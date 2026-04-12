# COMP 474 — Academic Course Advisor

A rule-based expert system for course planning in Concordia University's BCompSc program. Built in CLIPS for D1 and extended with Certainty Factor reasoning (FuzzyCLIPS) for D2.

## Project Information

**Course:** COMP 474 — Intelligent Systems (Winter 2026)

**Team:**
- Samisha Malhotra (40190420)
- Zhuang Zhang (40177899)
- Rayan Rekmani (40283058)

**Repository:** https://github.com/samishamalhotra/Comp474

## Requirements

This project requires **FuzzyCLIPS 6.31** (not vanilla CLIPS), because the D2 certainty factor rules use FuzzyCLIPS-specific syntax for CF declarations.

### Installing FuzzyCLIPS

```bash
cd ~
mkdir -p tools
cd tools
git clone https://github.com/garydriley/FuzzyCLIPS631.git
cd FuzzyCLIPS631/source
make fzclips
```

This produces an executable at `~/tools/FuzzyCLIPS631/source/fz_clips`.

On macOS, if `make` fails with a missing compiler error, run `xcode-select --install` first, then retry.

## How to Run

1. Navigate to the project folder:
```bash
cd /path/to/Comp474
```

2. Launch FuzzyCLIPS:
```bash
~/tools/FuzzyCLIPS631/source/fz_clips
```

3. Inside FuzzyCLIPS, load both files:
```
(load "factbase.clp")
(load "rulebase.clp")
```

4. Run the system:
```
(reset)
(run)
```

You will be prompted for a student ID, target semester, desired credit count, and workload preference. The system will then output (a) the eligible courses for the student and (b) a Recommendation Confidence Score for each course based on the D2 certainty factor rules.

## Common Commands

| Command | Purpose |
|---|---|
| `(reset)` `(run)` | Restart a session with the same loaded code |
| `(clear)` | Wipe all templates, rules, and facts from memory |
| `(facts)` | Display all facts currently in working memory |
| `(rules)` | List all defined rules |
| `(exit)` | Quit FuzzyCLIPS |

After editing `.clp` files, do `(clear)` followed by `(load ...)` for both files before running again — otherwise FuzzyCLIPS will complain about templates being redefined.

## Test Student IDs

| ID | Year | GPA | Profile |
|---|---|---|---|
| `S1001` | 1 | 3.5 | Strong, just started |
| `S1002` | 2 | 2.5 | Average, finished 200-level core |
| `S1003` | 3 | 3.2 | Average, deep into core |
| `S1004` | 4 | 3.8 | Strong, nearly done |
| `S1005` | 4 | 3.7 | Strong, AI track (completed COMP472, COMP474) |

S1005 was added in D2 specifically to demonstrate track-interest inference and CF combination across multiple signals. Use S1003 vs S1005 for the clearest contrast in recommendation confidence scores.

## File Structure

```
.
├── factbase.clp     # Templates and initial facts (course catalog, prereqs, students)
├── rulebase.clp     # All inference rules including D2 certainty factor rules
└── README.md        # This file
```