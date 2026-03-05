---
name: documentation-structure
description: "Establish and maintain documentation structure for AI-assisted projects (AGENTS.md, CLAUDE.md, README.md relationships). Activates for: documentation structure, setup docs, update docs, maintain docs, sync docs, AGENTS.md, CLAUDE.md, README.md, organize project docs, 文档结构, 更新文档, 维护文档, 同步文档, 设置文档, 组织项目文档。"
---

# Documentation Structure

Establish and maintain documentation structure across projects with clear separation between human-readable and AI-specific content.

## Core Principles

### File Hierarchy
- **AGENTS.md**: Primary AI instruction file (canonical source)
- **CLAUDE.md**: Symlink to AGENTS.md for compatibility
- **README.md**: Human-focused documentation (setup, usage, contribution)

### Relationship Pattern
- Minimal bidirectional references
- Clear audience separation (humans vs AI)
- Single source of truth (AGENTS.md)

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

3. **Ambiguous** (clarify):
   - Generic "更新文档" without context
   - Unclear whether structure or content
   - **Action**: Ask: "Are you updating documentation structure (AGENTS.md/CLAUDE.md relationships) or content (README.md text)?"

**Early exit for pure content updates:**

If intent is pure content update, provide brief guidance:
```
This skill handles documentation structure (AGENTS.md/CLAUDE.md/README.md relationships).

For content updates to README.md:
- Edit README.md directly with your changes
- Focus on: project overview, setup, usage, contributing

For structure setup/maintenance, mention "文档结构" or "AGENTS.md" explicitly.
```

### 1. Assess Current State

Check existing documentation structure:

```bash
ls -la README.md AGENTS.md CLAUDE.md 2>/dev/null || true
```

Identify:
- Which files exist
- Whether CLAUDE.md is a symlink or regular file
- Content overlap or conflicts

### 2. Establish AGENTS.md

**If AGENTS.md does not exist:**
- Create with project-specific AI instructions
- Include: coding standards, architecture decisions, workflow preferences

**If AGENTS.md exists:**
- Verify it contains necessary AI context
- Check for completeness and clarity

**Template structure:**
```markdown
# AI Agent Instructions

For project overview and setup instructions, see [README.md](./README.md).

## Project Context
[Brief project description and key architectural decisions]

## Coding Standards
[Project-specific coding conventions]

## Workflow Preferences
[Development workflow, testing approach, commit conventions]

## Architecture Notes
[Key architectural patterns and constraints]
```

### 3. Handle CLAUDE.md

**If CLAUDE.md does not exist:**
```bash
ln -s AGENTS.md CLAUDE.md
```

**If CLAUDE.md is already a symlink to AGENTS.md:**
- No action needed

**If CLAUDE.md is a regular file:**
- Review content carefully
- Determine if content should merge into AGENTS.md
- If merging:
  ```bash
  # Backup first
  cp CLAUDE.md CLAUDE.md.backup
  # Merge content into AGENTS.md (manual review required)
  # Then replace with symlink
  rm CLAUDE.md
  ln -s AGENTS.md CLAUDE.md
  ```
- If keeping separate: document rationale explicitly

### 4. Update README.md

Add minimal reference to AGENTS.md:

```markdown
## For AI Assistants

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

**Assessment criteria:**
- Is content project-specific or generic?
- Is content duplicated in AGENTS.md?
- Is content still relevant?

**Decision tree:**
1. If content is generic → merge into AGENTS.md
2. If content is project-specific and missing from AGENTS.md → merge into AGENTS.md
3. If content is outdated → archive and create symlink
4. If content serves a distinct purpose → document rationale and keep separate

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

- [ ] AGENTS.md exists and contains project-specific AI instructions
- [ ] CLAUDE.md is a symlink to AGENTS.md (or documented alternative)
- [ ] README.md references AGENTS.md in "For AI Assistants" section
- [ ] AGENTS.md references README.md for project overview
- [ ] Symlink verification passes: `ls -la CLAUDE.md`
- [ ] Both files are readable and show identical content
- [ ] README.md remains human-focused
- [ ] No content duplication between files
- [ ] Team members understand the structure (if applicable)
- [ ] Cross-platform considerations addressed (if applicable)

## Output

After completing the workflow, provide:

1. **Summary of actions taken:**
   - Files created or modified
   - Symlinks established
   - Content merged or moved

2. **Current structure:**
   ```bash
   ls -la README.md AGENTS.md CLAUDE.md
   ```

3. **Validation results:**
   - Symlink verification
   - Content consistency check
   - Reference validation

4. **Next steps (if any):**
   - Manual review needed
   - Team communication required
   - Documentation updates pending
