# NAMING

Read before naming any file, symbol, branch, ID, or config key.

**Inherited** rules hold across every project - do not change them here.
**Project-specific** rules are true only in this repo - they do not travel with copied code.

Every rule gets a good and a bad example.
A convention stated abstractly gets interpreted; a convention with a counter-example gets followed.

<!-- scaffold:section=inherited -->

## Inherited

| Thing          | Rule                                          | Good                             | Bad                |
| -------------- | --------------------------------------------- | -------------------------------- | ------------------ |
| Branches       | `<type>/<short-kebab>`                        | `feat/chord-namespace`           | `my-fix-2`         |
| Commits        | `<type>(<scope>): <imperative>`               | `fix(export): keep when clause`  | `fixed stuff`      |
| Markdown files | `SCREAMING_SNAKE.md` at root, `kebab-case.md` elsewhere | `COMPASS.md`, `docs/chord-map.md` | `docs/ChordMap.md` |
| IDs            | 5 lowercase alphanumerics, minted at random  | `a3f9c2`, `x7q2m`                | `issue42`          |

<!-- scaffold:section=project -->

## Project-specific

| Thing   | Rule   | Good    | Bad    |
| ------- | ------ | ------- | ------ |
| <thing> | <rule> | <good>  | <bad>  |

<!-- scaffold:section=reserved -->

## Reserved

Terms that already mean something here. Do not reuse them for anything else.

| Term    | Means     | Do not use for |
| ------- | --------- | -------------- |
| <term>  | <meaning> | <what to avoid> |

<!-- scaffold:section=changing -->

## Changing a rule

Edit the row, then log the change with `log-issue.sh` so the reason survives.
A convention with no recorded reason gets silently reverted by the next person.
