# AGENTS.md — Dotfiles Repo

Persistent guidance for AI agents working in this repository.

---

## Project Overview

This is a personal development environment automation framework using Ansible. Running `bin/dotfiles [profile]` bootstraps a machine from scratch — installing tools, deploying config files, and setting up SSH keys. It targets **macOS (primary)** and **WSL/Windows (maintained but less frequently changed)**.

---

## Entry Point

```bash
bin/dotfiles           # personal profile (default)
bin/dotfiles work      # work profile
```

`bin/dotfiles` bootstraps dependencies (Homebrew, git, pipx, Ansible, 1Password CLI), then runs `ansible-playbook --diff -e "profile=<PROFILE>" main.yml`.

---

## Architecture

### Profile System

The single source of truth is `group_vars/all.yml`. Each role and SSH key is annotated with which profiles it applies to:

```yaml
dotfiles_roles:
  - name: ghostty
    profiles: [personal, work]
  - name: burpsuite
    profiles: [personal]

ssh_keys:
  - name: id_ed25519
    profiles: [personal]
    op_private_key: "op://Personal/SSH Key/private key"
    op_public_key: "op://Personal/SSH Key/public key"
```

`main.yml` filters `dotfiles_roles` at runtime using `selectattr('profiles', 'contains', profile)`. The `ssh` role does the same for `ssh_keys`. **Never create separate per-profile files** — all role/key assignments live in `all.yml` only.

### Role Structure

Every role follows this layout:

```
roles/<name>/
  tasks/
    main.yml      # OS dispatch (import darwin.yml / wsl.yml)
    darwin.yml    # macOS-specific tasks
    wsl.yml       # WSL/Windows-specific tasks (if applicable)
  files/          # Static files
  templates/      # Jinja2 templates (.j2)
```

`main.yml` dispatches by platform:
```yaml
- name: Run macOS tasks
  ansible.builtin.import_tasks: darwin.yml
  when: ansible_os_family == 'Darwin'

- name: Run WSL tasks
  ansible.builtin.import_tasks: wsl.yml
  when: ansible_host_environment_is_wsl
```

### Pre-tasks

`pre_tasks/` runs before roles on every invocation (tagged `always`):
- `detect_wsl.yml` — sets `ansible_host_environment_is_wsl` (boolean)
- `whoami.yml` — sets `host_user`
- `whoami_wsl.yml` — sets `wsl_host_user` (WSL only)
- `powershell_executionpolicy.yml` — WSL only

---

## Conventions

### Always Create a Dedicated Role

Even for a single `brew install`, create a role. Never add a tool's install task into an unrelated role.

### FQCN for All Modules

Always use fully-qualified collection names:
```yaml
# ✅ correct
ansible.builtin.copy:
community.general.homebrew:

# ❌ wrong
copy:
homebrew:
```

### Homebrew Tasks

Use `community.general.homebrew` for CLI tools and `community.general.homebrew_cask` for GUI apps. Both are already idempotent with `state: present` — no additional guards needed.

### Windows / WSL Package Installation

Use the `winget` role via `ansible.builtin.include_role`:
```yaml
- name: Install <tool>
  ansible.builtin.include_role:
    name: winget
  vars:
    winget_packages:
      - <WingetPackageId>
```

### File Permissions

Always set `mode:` on `copy`, `template`, and `file` tasks. Standard values:
- Directories: `"0755"`
- Executable files: `"0755"`
- Config files: `"0644"`
- SSH private keys: `"0600"`

### Templates vs Static Files

If a file contains any path or user-specific value, it must be a Jinja2 template (`.j2`) in `templates/`, not a static file in `files/`. Use `{{ ansible_user_dir }}` instead of `/Users/george/` or `$HOME`.

### Idempotency

Every task must be safe to run repeatedly. Do not use `--force` flags (shell or galaxy) unless wrapped in a condition that prevents unnecessary re-runs. Use `creates:` for shell tasks that bootstrap tools.

---

## Secrets and 1Password

This repo uses 1Password CLI (`op`) for all secrets. The bootstrap gate in `bin/dotfiles` requires `op` to be installed and authenticated before the playbook runs.

**When adding a new secret:**
- Always ask the user for the exact `op://Vault/Item/field` path — do not guess or invent paths
- Store the reference as a variable in `group_vars/all.yml`, not inline in a task
- Fetch at runtime using `ansible.builtin.command: op read "{{ variable }}"` with `no_log: true` for sensitive values

---

## ansible-lint

The repo enforces the `production` lint profile. **Always run `ansible-lint` outside the sandbox and fix all errors before considering any task complete:**

```bash
cd ~/.dotfiles && ansible-lint
```

Skipped rules (configured in `.ansible-lint`):
- `name[template]` — dynamic task names are intentional
- `no-changed-when` — some shell tasks legitimately always change

Mocked modules: `community.general.homebrew`, `community.general.homebrew_cask` (not available in CI lint environment).

If a lint rule genuinely cannot be fixed (e.g. `risky-file-permissions` on `lineinfile` which has no `mode` parameter), add a targeted `# noqa: <rule>` inline comment on the task's `name:` line — not on the module line.

---

## GitHub Actions CI

`.github/workflows/lint.yml` runs `ansible-lint` + `ansible-playbook --syntax-check main.yml` on every push and PR to `main`. The CI uses `--force` for collection install (intentional — clean environment each run). Local development uses `--upgrade` instead.

---

## Adding a New Role — Checklist

1. Create `roles/<name>/tasks/main.yml` with OS dispatch
2. Create `roles/<name>/tasks/darwin.yml` (and `wsl.yml` if needed)
3. Add the role to `dotfiles_roles` in `group_vars/all.yml` with appropriate `profiles`
4. Run `ansible-lint` and fix all errors

---

## What Agents Should Never Do

- **Never commit** unless the user explicitly asks
- **Never invent `op://` paths** — always ask for the exact reference
- **Never add a tool to an existing role** — always create a dedicated role
- **Never use `become: yes`** — this runs locally as the current user, privilege escalation is not needed
- **Never duplicate role lists across profile files** — `group_vars/all.yml` is the single source of truth
- **Never leave trailing spaces or missing end-of-file newlines** in YAML files — ansible-lint will catch them
