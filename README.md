# Reproduction: a cache hit replays recorded color codes under `--no-color` and `NO_COLOR`

Made from `npx create-turbo@canary -e with-shell-commands`, with `turbo` at `2.11.12-canary.3` and one task added:
`app-a`'s `paint` prints `color=` and then a red `red` when `FORCE_COLOR` is set, `plain` when it is not.

```sh
./reproduce.sh        # needs pnpm 11; or:
./run-in-docker.sh    # runs reproduce.sh in Docker's node:26 image with pnpm 11.22.0
```

`reproduce.sh` installs, clears `.turbo`, prints `turbo info`, then runs `turbo run paint --filter=app-a --ui=stream`
four times: with `FORCE_COLOR=3`, with `--no-color`, with `NO_COLOR=1`, and with `--force` and no color asked. It
prints each run's cache status line and the task's `color=` line with escape codes shown as `^[`, and exits 1 while
the `--no-color` or the `NO_COLOR=1` run prints a color code in the task's line, 0 once neither does, and 2 when a step
fails or a run prints something else.

---

# Turborepo starter with shell commands

This Turborepo starter is maintained by the Turborepo core team. This template is great for issue reproductions and exploring building task graphs without frameworks.

## Using this example

Run the following command:

```sh
npx create-turbo@latest -e with-shell-commands
```

### For bug reproductions

Giving the Turborepo core team a minimal reproduction is the best way to create a tight feedback loop for a bug you'd like to report.

Because most monorepos will rely on more tooling than Turborepo (frameworks, linters, formatters, etc.), it's often useful for us to have a reproduction that strips away all of this other tooling so we can focus _only_ on Turborepo's role in your repo. This example does exactly that, giving you a good starting point for creating a reproduction.

- Feel free to rename/delete packages for your reproduction so that you can be confident it most closely matches your use case.
- If you need to use a different package manager to produce your bug, run `pnpm dlx @turbo/workspaces convert` to switch package managers.
- It's possible that your bug really **does** have to do with the interaction of Turborepo and other tooling within your repository. If you find that your bug does not reproduce in this minimal example and you're confident Turborepo is still at fault, feel free to bring that other tooling into your reproduction.

## What's inside?

This Turborepo includes the following packages:

### Apps and Packages

- `app-a`: A final package that depends on all other packages in the graph and has no dependents. This could resemble an application in your monorepo that consumes everything in your monorepo through its topological tree.
- `app-b`: Another final package with many dependencies. No dependents, lots of dependencies.
- `pkg-a`: A package that defines all of the example's task scripts.
- `pkg-b`: A package with _almost_ all of the example's task scripts.
- `tooling-config`: A package to simulate a common configuration used for all of your repository. This could resemble a configuration for tools like TypeScript or ESLint that are installed into all of your packages.

### Some commands to try

Run tasks with the repository's pinned version of `turbo`:

- `pnpm turbo build lint check-types`: Runs all tasks in the default graph.
- `pnpm turbo build`: A basic command to build `app-a` and `app-b` in parallel.
- `pnpm turbo build --filter=app-a`: Builds only `app-a` and its dependencies.
- `pnpm turbo lint`: Runs lints in all packages in parallel.
