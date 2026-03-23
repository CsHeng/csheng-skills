---
name: documentation-structure
description: "Establish, maintain, and organize documentation structure for AI-assisted projects (AGENTS.md, CLAUDE.md, README.md relationships and content separation). Activates for: documentation structure, setup docs, update docs, maintain docs, sync docs, organize docs, tidy docs, AGENTS.md, CLAUDE.md, README.md, organize project docs, separate human/AI docs, consolidate CLAUDE.md, 文档结构, 更新文档, 维护文档, 同步文档, 设置文档, 组织项目文档, 整理文档, 文档整理, 文档分离。"
---

# Documentation Structure

Establish, maintain, and organize documentation structure across projects with clear audience separation and content tidying between human-readable and AI-specific files.

## Core Principles

### File Hierarchy
- **README.md**: Human-focused documentation (project overview, setup, usage, contribution)
- **AGENTS.md**: AI/LLM-focused instructions (coding standards, architecture context, workflow rules)
- **CLAUDE.md**: Symlink to AGENTS.md (compatibility layer, not a standalone file)
- **docs/**: Detailed documentation split by domain when root files exceed thresholds

### Relationship Pattern
- Clear audience separation: humans read README.md, AI reads AGENTS.md
- Minimal bidirectional references between README.md and AGENTS.md
- Single source of truth for AI instructions: AGENTS.md
- CLAUDE.md is always a symlink, never a standalone file
- Long content splits to docs/ with summary + reference in root files

### Content Classification Rules

Content belongs in **README.md** (human audience):
- Project overview and purpose
- Installation and setup instructions
- Usage examples and API documentation
- Contributing guidelines and code of conduct
- License information
- Badges, screenshots, demo links
- Changelog or release notes references

Content belongs in **AGENTS.md** (AI/LLM audience):
- Coding standards and conventions
- Architecture decisions and constraints
- Workflow preferences (commit style, branching, review process)
- File structure and module boundaries
- Testing strategy and quality gates
- Environment-specific rules (Docker, CI/CD, deployment)
- Tool preferences and version requirements
- Security and validation rules

Content that does NOT belong in either:
- Secrets, credentials, API keys → use .env or secret management
- Temporary task state → use issue tracker or TODO comments
- Personal preferences not shared with team → use local config

## Workflow

### 0. Intent Assessment (Entry Point)

**Determine user intent and current state:**

```bash
# Check existing files
ls -la README.md AGENTS.md CLAUDE.md 2>/dev/null || true
```

**Intent classification:**

1. **Pure content update** (exit early):
   - User wants to update README.md content (features, setup instructions, etc.)
   - No mention of AGENTS.md, CLAUDE.md, or structure
   - Example: "更新 README 添加新功能说明"
   - **Action**: Provide brief guidance, exit skill

2. **Structure-related** (proceed with full workflow):
   - Mentions AGENTS.md, CLAUDE.md, or documentation structure
   - Wants to establish/fix symlinks or file relationships
   - Wants to ensure structure compliance
   - Example: "更新文档，确保 AGENTS.md 和 CLAUDE.md 同步"
   - **Action**: Proceed to step 1

3. **Content organization** (proceed with full workflow + tidying):
   - Wants to reorganize content between files by audience
   - Mentions "整理", "organize", "tidy", "separate", "分离"
   - AI-facing content mixed into README.md needs moving to AGENTS.md
   - Human-facing content mixed into AGENTS.md needs moving to README.md
   - Example: "整理文档，把 AI 相关内容移到 AGENTS.md"
   - **Action**: Proceed to step 1, with step 2.5 (Content Tidying) as mandatory

4. **Ambiguous** (clarify):
   - Generic "更新文档" without context
   - Unclear whether structure, content, or organization
   - **Action**: Ask: "Are you updating documentation structure (AGENTS.md/CLAUDE.md relationships), content (README.md text), or organizing content between files (audience separation)?"

**Early exit for pure content updates:**

If intent is pure content update, provide brief guidance:
```
This skill handles documentation structure and content organization.

For content updates to README.md:
- Edit README.md directly with your changes
- Focus on: project overview, setup, usage, contributing

For content organization (moving AI content to AGENTS.md, human content to README.md):
- Mention "整理文档" or "organize docs" explicitly.

For structure setup/maintenance:
- Mention "文档结构" or "AGENTS.md" explicitly.
```

### 1. Assess Current State

Check existing documentation structure:

```bash
ls -la README.md AGENTS.md CLAUDE.md 2>/dev/null || true
ls -d docs/ 2>/dev/null || true
```

Read all existing files as a unified content pool:
- Read README.md, AGENTS.md, CLAUDE.md (if they exist)
- Check docs/ structure if exists
- Treat their combined content as a single body to be restructured
- Identify content that is misplaced by audience (human vs AI)

Identify:
- Which files exist
- Whether CLAUDE.md is a symlink or regular file
- Content overlap, conflicts, or misplaced content
- Total content volume and quality
- **Length metrics:**
  - AGENTS.md line count (split threshold: >500 lines or single section >150 lines)
  - README.md line count (split threshold: >300 lines or setup/usage >100 lines)
  - Number of independent business domains (split threshold: ≥3 domains)

**Initialization detection:**

If the existing files appear minimal or generic (e.g., only a project title, no project-specific instructions, boilerplate-only content), the project likely has not been properly initialized:

- README.md has fewer than 10 meaningful lines, or
- AGENTS.md does not exist or contains no project-specific rules, or
- Files contain only template placeholders

**Action when uninitialized:**
```
The documentation files appear minimal or uninitialized.
Recommend running project initialization first (e.g., /init or equivalent)
to generate project-specific content, then re-run this skill to organize
the resulting documentation by audience.
```

If the user confirms initialization is not needed, proceed with available content.

### 2. Establish AGENTS.md

**If AGENTS.md does not exist:**
- Create with project-specific AI/LLM instructions
- Extract AI-relevant content from README.md or CLAUDE.md if available
- Include: coding standards, architecture decisions, workflow preferences, tool requirements

**If AGENTS.md exists:**
- Verify it contains AI-specific context (not human-facing content)
- Flag any human-facing content (setup instructions, usage examples) for migration to README.md

**Template structure:**
```markdown
# AI Agent Instructions

For project overview and setup instructions, see [README.md](./README.md).

## Project Context
[Brief project description and key architectural decisions]

## Repository Layout
[Key directories and their purposes]

## Coding Standards
[Project-specific coding conventions, linting, formatting]

## Workflow Preferences
[Development workflow, commit conventions, branching strategy]

## Architecture Notes
[Key architectural patterns, constraints, module boundaries]

## Tool Requirements
[Required tool versions, package managers, build tools]

## Validation
[How to run tests, lint, type checks]
```

### 2.5. Content Tidying (Restructure by Audience)

This step treats all existing file content as a unified pool and redistributes it by audience. Always run this step when intent is "content organization". For "structure-related" intent, run if misplaced content is detected in Step 1.

**Process:**

1. Collect all content from README.md, AGENTS.md, and CLAUDE.md (if regular file)
2. Classify each section/paragraph using Content Classification Rules:
   - Human-facing → README.md
   - AI/LLM-facing → AGENTS.md
   - Neither → remove or relocate (see classification rules)
3. Deduplicate: if the same information exists in multiple files, keep one copy in the correct file
4. Restructure each file:
   - README.md: reorder to follow human-readable flow (overview → setup → usage → contributing → license → AI reference)
   - AGENTS.md: reorder to follow AI-consumable flow (context → layout → standards → workflow → architecture → tools → validation)
5. Add cross-references:
   - README.md gets "For Agents" section pointing to AGENTS.md
   - AGENTS.md gets "For project overview, see README.md" at top

**Common misplacements to fix:**

| Found in | Content type | Move to |
|----------|-------------|---------|
| README.md | Coding standards, lint rules | AGENTS.md |
| README.md | Architecture constraints, module boundaries | AGENTS.md |
| README.md | Commit conventions, review process | AGENTS.md |
| AGENTS.md | Installation instructions | README.md |
| AGENTS.md | Usage examples, API docs | README.md |
| AGENTS.md | Badges, screenshots, demo links | README.md |
| CLAUDE.md | Any content | AGENTS.md (AI) or README.md (human) |

**Preserve intent:** When moving content, preserve the original meaning and context. Rewrite section headers to fit the target file's style if needed, but do not alter the substance.

### 2.7. Long Document Splitting

Run this step when length thresholds are exceeded (detected in Step 1).

**Trigger conditions:**
- AGENTS.md >500 lines OR single section >150 lines
- README.md >300 lines OR setup/usage section >100 lines
- 3+ independent business domains in one file

**Domain classification:**

| Domain | Content types | Target directory |
|--------|--------------|------------------|
| Architecture | System design, module boundaries, data flow, component diagrams | `docs/architecture/` |
| Development | Workflow, testing strategy, deployment, CI/CD | `docs/development/` |
| Standards | Coding standards, API conventions, security guidelines, quality gates | `docs/standards/` |
| Guides | Setup guide, troubleshooting, contribution guide, usage examples | `docs/guides/` |

**Splitting process:**

1. **Create docs/ structure:**
   ```bash
   mkdir -p docs/{architecture,development,standards,guides}
   ```

2. **Identify split candidates:**
   - Scan AGENTS.md/README.md for sections matching domain classification
   - Prioritize sections >150 lines (AGENTS.md) or >100 lines (README.md)
   - Group related subsections under same domain

3. **Extract and relocate:**
   - Move complete sections with headers to `docs/{domain}/{topic}.md`
   - Keep 1-2 sentence summary in original file
   - Add reference link: `For detailed [topic], see [docs/domain/file.md](docs/domain/file.md)`

4. **Preserve context:**
   - Extracted files should be self-contained (include necessary context)
   - Add breadcrumb at top: `Part of [AGENTS.md](../../AGENTS.md) / [README.md](../../README.md)`

**Example transformation:**

Before (AGENTS.md, 600 lines):
```markdown
## Coding Standards

### Python Standards
[50 lines]

### Go Standards
[50 lines]

### Shell Standards
[50 lines]

## Architecture

### System Design
[100 lines]

### Module Boundaries
[100 lines]
```

After (AGENTS.md, 80 lines):
```markdown
## Coding Standards

Follow project coding standards for Python, Go, and Shell. See [docs/standards/coding-standards.md](docs/standards/coding-standards.md).

## Architecture

System follows clean architecture with clear module boundaries. See [docs/architecture/system-design.md](docs/architecture/system-design.md) and [docs/architecture/module-boundaries.md](docs/architecture/module-boundaries.md).
```

After (docs/standards/coding-standards.md):
```markdown
# Coding Standards

Part of [AGENTS.md](../../AGENTS.md)

## Python Standards
[50 lines]

## Go Standards
[50 lines]

## Shell Standards
[50 lines]
```

**Skip splitting if:**
- Total content <200 lines (too small to benefit)
- Content is already well-organized and readable
- User explicitly requests keeping content in root files

### 3. Consolidate CLAUDE.md into AGENTS.md

CLAUDE.md is not a standalone file. Its content belongs in AGENTS.md.

**If CLAUDE.md does not exist:**
```bash
ln -s AGENTS.md CLAUDE.md
```

**If CLAUDE.md is already a symlink to AGENTS.md:**
- No action needed

**If CLAUDE.md is a regular file (consolidation required):**
1. Read CLAUDE.md content
2. Classify each section by audience using Content Classification Rules
3. Merge AI-facing content into AGENTS.md (deduplicate against existing content)
4. Migrate any human-facing content to README.md
5. Replace CLAUDE.md with symlink:
   ```bash
   cp CLAUDE.md CLAUDE.md.backup
   rm CLAUDE.md
   ln -s AGENTS.md CLAUDE.md
   ```
6. Verify backup can be safely removed after review

**Decision: always consolidate.** There is no valid reason to keep CLAUDE.md as a separate file. If content exists in CLAUDE.md, it either belongs in AGENTS.md (AI-facing) or README.md (human-facing).

### 4. Update README.md

Add minimal reference to AGENTS.md:

```markdown
## For Agents

AI-specific instructions and context are in [AGENTS.md](./AGENTS.md).
```

**Placement:**
- Near end of README (after main content)
- Before or after "Contributing" section

**Keep README human-focused:**
- Project overview
- Installation and setup
- Usage examples
- Contributing guidelines
- License

### 5. Validate Structure

**Verify symlink:**
```bash
ls -la CLAUDE.md
# Should show: CLAUDE.md -> AGENTS.md
```

**Verify readability:**
```bash
head -5 AGENTS.md
head -5 CLAUDE.md
# Should show identical content
```

**Check references:**
- README.md links to AGENTS.md
- AGENTS.md links to README.md
- Both links are valid

## Edge Cases

### Cross-Platform Projects (Windows)

**Problem:** Symlinks may not work on Windows or in some cloud editors

**Solution:**
- Use file copy with sync mechanism
- Document sync approach in project documentation
- Consider git hooks to keep files in sync:
  ```bash
  # .git/hooks/pre-commit
  if [ -f AGENTS.md ]; then
    cp AGENTS.md CLAUDE.md
    git add CLAUDE.md
  fi
  ```

### Team Projects

**Requirements:**
- Document this structure in team conventions
- Ensure all team members understand file relationships
- Include in onboarding documentation

**Communication:**
- Add to CONTRIBUTING.md or team wiki
- Mention in PR templates or review checklists

### Existing CLAUDE.md with Unique Content

**Always consolidate.** CLAUDE.md is a compatibility symlink, not a standalone file.

**Process:**
1. Classify all CLAUDE.md content by audience using Content Classification Rules
2. AI-facing content → merge into AGENTS.md (deduplicate)
3. Human-facing content → merge into README.md (deduplicate)
4. Outdated content → discard
5. Replace CLAUDE.md with symlink to AGENTS.md

### Monorepo or Multi-Project Structure

**Pattern:**
- Root-level AGENTS.md for global conventions
- Per-project AGENTS.md for project-specific context
- Root CLAUDE.md symlinks to root AGENTS.md
- Per-project CLAUDE.md symlinks to per-project AGENTS.md

**Example:**
```
/
├── AGENTS.md (global conventions)
├── CLAUDE.md -> AGENTS.md
├── project-a/
│   ├── AGENTS.md (project-specific)
│   ├── CLAUDE.md -> AGENTS.md
│   └── README.md
└── project-b/
    ├── AGENTS.md (project-specific)
    ├── CLAUDE.md -> AGENTS.md
    └── README.md
```

## Maintenance

### When to Update

**Update AGENTS.md when:**
- New coding standards are adopted
- Architecture decisions change
- Workflow preferences evolve
- New patterns or conventions emerge

**Update README.md when:**
- Setup instructions change
- New features are added
- Usage examples need updates
- Contributing guidelines change

### Sync Considerations

**If using symlinks:**
- No sync needed (automatic)

**If using file copies:**
- Establish sync mechanism (git hooks, CI checks)
- Document sync process clearly
- Consider automation to prevent drift

## Validation Checklist

- [ ] AGENTS.md exists and contains only AI/LLM-facing instructions
- [ ] README.md exists and contains only human-facing documentation
- [ ] CLAUDE.md is a symlink to AGENTS.md (no exceptions)
- [ ] No AI-facing content remains in README.md (coding standards, architecture rules, workflow preferences)
- [ ] No human-facing content remains in AGENTS.md (setup instructions, usage examples, badges)
- [ ] README.md references AGENTS.md in "For Agents" section
- [ ] AGENTS.md references README.md for project overview
- [ ] Symlink verification passes: `ls -la CLAUDE.md`
- [ ] No content duplication between README.md and AGENTS.md
- [ ] Content from former CLAUDE.md fully redistributed (if applicable)
- [ ] Cross-platform considerations addressed (if applicable)
- [ ] If docs/ exists: structure follows `{architecture,development,standards,guides}/` pattern
- [ ] If docs/ exists: all extracted files have breadcrumb references to root files
- [ ] If docs/ exists: root files contain summary + reference links to detailed docs
- [ ] Length thresholds respected: AGENTS.md <500 lines, README.md <300 lines (or splitting justified)

## Output

After completing the workflow, provide:

1. **Summary of actions taken:**
   - Files created, modified, or consolidated
   - Symlinks established
   - Content migrated between files (what moved, from where, to where)
   - docs/ structure created (if applicable)

2. **Content migration report** (if tidying was performed):
   - Sections moved from README.md → AGENTS.md
   - Sections moved from AGENTS.md → README.md
   - Content consolidated from CLAUDE.md (destination of each section)
   - Content removed (duplicates, outdated)

3. **Long document splitting report** (if Step 2.7 was executed):
   - Sections extracted from AGENTS.md → docs/ (domain, file path, line count)
   - Sections extracted from README.md → docs/ (domain, file path, line count)
   - Summary references added to root files
   - Final line counts: AGENTS.md, README.md

4. **Current structure:**
   ```bash
   ls -la README.md AGENTS.md CLAUDE.md
   ls -R docs/ 2>/dev/null || echo "No docs/ directory"
   ```

5. **Validation results:**
   - Symlink verification
   - Audience separation check
   - Reference validation
   - Length threshold compliance

6. **Next steps (if any):**
   - Manual review needed
   - Initialization recommended (if files were minimal)
   - Team communication required
