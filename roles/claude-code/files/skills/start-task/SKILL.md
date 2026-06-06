---
name: start-task
description: >-
  Kick off a fresh, isolated unit of work in a project the right way: spin up a
  dedicated git worktree so the task can't collide with other work, pin down its
  scope and resolve the genuinely open questions, route the work to the
  best-suited subagents (project-defined first), then report back and offer to
  commit + push. Use this whenever the user signals they're starting a new task
  or piece of work — "let's start a new task", "I want to work on…", "kick off…",
  "begin work on…", "new feature/bugfix", picking up a ticket/issue, or any time
  fresh work deserves to be isolated from the current branch. Reach for it even
  when the user doesn't say "worktree" or "skill" out loud, as long as they're
  starting something new. Don't use it for trivial one-line tweaks, for
  answering questions, or for continuing work already in progress on the current
  branch.
---

# Start Task

This skill is the on-ramp for a new piece of work. Its job is to make sure every
task starts *clean and well-scoped*: isolated from other work, understood before
it's begun, handed to whoever (or whatever) is best equipped to do it, and wound
up with a tidy summary and an offer to commit. Following it turns a vague "let's
work on X" into a confident, reproducible start.

The spine of the flow — each step earns its place, don't skip them:

1. **Capture & confirm the task** — know exactly what you're starting before you start.
2. **Isolate in a worktree** — so this task can't trip over anything else.
3. **Build the context** — answer what you can yourself; ask the user only what's genuinely uncertain.
4. **Choose the agents** — match the work to the most bespoke help available.
5. **Do the work** — delegate to those agents, integrate, verify.
6. **Report back & hand off** — summarize, then offer to commit + push.

Move through these in order, but stay human about it: if the user has already
given you most of what a step needs, confirm it quickly and move on rather than
re-interrogating them.

---

## Step 1 — Capture and confirm the task

You can't isolate or scope work you don't understand, so this comes first.

- **If the user already described the task**, restate it back in one or two
  crisp sentences — what they want and roughly why — and ask them to confirm or
  correct. This catches misreads cheaply, before a worktree or any work exists.
- **If the user hasn't said what the task is**, your first move is to ask. Keep
  it open: *"What would you like to start working on?"* Don't guess a task into
  existence.

Don't proceed past this step until the user has confirmed the summary. A wrong
summary poisons everything downstream, and it's the one thing only the user can
settle.

---

## Step 2 — Isolate the work in a worktree

Every task starts in its own git worktree. The point is isolation: the new work
gets a clean branch and its own working directory, so it can't entangle with
uncommitted changes, half-finished branches, or another task running in
parallel. This is non-negotiable for this skill — it's the whole reason "start a
task" is different from "just start editing."

**Before creating it, sanity-check the ground:**

- **Confirm you're in a git repository.** `EnterWorktree` needs one (or
  configured worktree hooks). If you're not in a project repo, tell the user and
  stop — don't silently start work in the wrong place.
- **Check you're not already in a worktree session.** `EnterWorktree` refuses to
  nest. If the session is already in a worktree for some other task, surface
  that to the user and ask whether to finish/exit that one first rather than
  forcing it.

**Create it** with the `EnterWorktree` tool, giving it a short, readable name
derived from the task — a kebab-case slug like `rate-limit-login` or
`fix-csv-export`, not a generic `task1`:

```
EnterWorktree({ name: "<task-slug>" })
```

This creates the worktree under `.claude/worktrees/<slug>` on a fresh branch
(by default branched from `origin/<default-branch>`) and switches the session
into it. From here on, everything happens inside the isolated worktree.

One thing to flag if relevant: a fresh worktree branches from the remote
default, so **uncommitted changes in the original directory won't come along.**
If the user clearly wants to build on local work-in-progress, say so and let them
decide (they may want the `worktree.baseRef: head` setting, or to commit/stash
first) before you proceed.

---

## Step 3 — Build the context

Now make the task *workable*. The goal is a short, shared understanding of scope
and approach before any code is touched — enough that the work won't veer off or
stall on an unknown halfway through.

The discipline that makes this good rather than annoying: **answer everything you
can yourself, and ask the user only the questions you genuinely can't settle.**
Their time is the scarce resource. Burning it on questions the codebase already
answers makes the skill feel like a form to fill out.

So, in order:

1. **Investigate first.** Read the relevant code, search for the affected areas,
   skim CLAUDE.md / AGENTS.md / READMEs, look at how similar things are done in
   this repo. Most "open questions" dissolve once you've actually looked.
2. **List what's still genuinely open** after investigating — the real forks
   where you can't confidently pick: ambiguous scope boundaries, competing valid
   approaches, acceptance criteria, anything with a product/preference dimension
   the code can't reveal. **Prioritize the questions whose answers you're least
   confident about** — those are where a wrong assumption costs the most.
3. **Ask the user those, and only those.** Prefer crisp, structured choices
   (use `AskUserQuestion`) with a recommended default, so answering is a quick
   click rather than an essay. Skip anything you can reasonably default and
   mention in your brief instead.
4. **Write a short task brief** and confirm it: the scope, the acceptance
   criteria ("done when…"), what's explicitly out of scope, the areas/files
   likely touched, and the intended approach. This brief is doing double duty —
   it's the agreement with the user *and* the instructions you'll hand to the
   subagents in Step 5, so make it concrete.

Keep it proportional: a one-file bugfix needs a couple of lines of context, not
an interrogation. A new subsystem warrants more.

---

## Step 4 — Choose the agents

Before doing the work, decide *who* should do it. The principle: prefer the most
bespoke help available, because an agent tuned to this project will know its
conventions, pitfalls, and tools far better than a generic one.

Work outward from most-specific to least:

1. **Project-scoped agents first.** Look in the repo's `.claude/agents/` and at
   the subagent types available to the `Agent` tool. These are hand-built for
   *this* project and almost always the best fit when one matches.
   - To judge fit, **consult CLAUDE.md / AGENTS.md** — they often document what
     each agent is for. Read the agent file's own `description` frontmatter too.
   - **If there's no documentation, infer from the agent's name.** A
     `migration-writer` or `api-reviewer` tells you plenty; use that.
2. **Then global agents.** If no project agent suits, assess globally defined
   agents (`~/.claude/agents/`) and the built-in types (`general-purpose`,
   `Explore`, `Plan`).
3. **Graceful fallback.** If nothing specialized fits — which is common, since
   many projects define no custom agents — that's fine. Use `general-purpose`
   for substantial work, or just do it inline yourself. Never shoehorn a
   bad-fit agent onto a task; a wrong specialist is worse than a capable
   generalist.

A real task often needs *several* agents — e.g. an implementer, a test author,
and a reviewer. Map the brief's pieces to the right helpers rather than assuming
one agent does it all. Then tell the user, in a sentence, which agents you chose
and why, so the routing is transparent.

---

## Step 5 — Do the work

Delegate the work to the agents you chose, then own the integration.

- **Hand each agent a focused slice** with the relevant part of the task brief:
  the goal, the acceptance criteria, the constraints, and which files/areas it
  concerns. A well-scoped prompt is what makes a subagent effective.
- **Run independent slices in parallel** — issue multiple `Agent` calls in a
  single turn when the pieces don't depend on each other, so they progress at
  once. Sequence them only where one genuinely needs another's output.
- **You are the orchestrator, not a bystander.** Integrate the results, resolve
  conflicts between them, and *verify the work actually holds* — run the build,
  the tests, the linters as appropriate to the repo. Iterate until the
  acceptance criteria from the brief are met. Subagents can be confidently
  wrong; your job is to catch that before the user sees it.
- Keep the user posted on meaningful milestones, but don't narrate every step.

---

## Step 6 — Report back and hand off

When the work is done and verified, close the loop.

- **Tell the user it's finished**, and give a tight summary they can actually
  act on:
  - what changed (the files/areas, the gist of the change),
  - the key decisions or trade-offs you made,
  - how you verified it (tests run, build passing, etc.),
  - anything deferred or deliberately left out of scope.
- **Then ask whether they're ready to commit and push.** Don't commit
  unprompted — the user owns that gate.

When they confirm:

- Stage the changes, write a commit message that **follows the repository's
  conventions** (glance at recent `git log`, any CONTRIBUTING/commit-style
  guidance, and required trailers — some repos mandate a co-author trailer),
  commit, and push the branch (`git push -u origin <branch>`).
- Report back the branch name and commit, so the user knows exactly what landed
  where.
- Stop there. Opening a PR isn't part of this flow unless the user asks — offer
  it as a next step if it fits, but don't assume it.

If the user *isn't* ready to commit, leave the work intact in the worktree and
let them know it's preserved there (and that `ExitWorktree` can keep or discard
it whenever they decide). The whole point of the isolation was to make pausing
safe.

---

## Keep in mind

- **Don't skip the worktree.** It's the feature, not overhead. If isolation
  truly doesn't make sense for what the user's doing, this probably isn't the
  right skill for the moment — say so rather than half-applying it.
- **Confirm before you commit to a direction**, twice specifically: the task
  summary (Step 1) and the task brief (Step 3). Those are the cheap moments to
  catch a misunderstanding.
- **Ask less, investigate more.** Every question you can answer from the code is
  a question the user doesn't have to.
- **Stay proportional.** Scale the ceremony to the task — a typo fix and a new
  feature should not feel the same to the user.
