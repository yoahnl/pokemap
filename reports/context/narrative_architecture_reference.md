# Three-Tier Narrative Architecture Reference

## Overview
This document provides a reference for the three-tier narrative architecture implemented in the Pokémon-like game editor project. Understanding these layers is crucial for maintaining proper separation of concerns and user experience.

## The Three Tiers

### 1. Global Story (Macro Progression)
**Purpose**: Represents the game's high-level narrative structure
**Responsibilities**:
- Overall story flow and progression
- Chapter organization and structure
- Macro-level branching and convergence
- Entry points and global transitions
- Relationship between major story beats

**What it should NOT handle**:
- Detailed dialogues
- Specific character movements
- Scene-by-scene scripting
- Fine-grained conditional logic
- Individual event details

**User Interface Characteristics**:
- Top-down, hierarchical view
- Chapter-based organization
- Compact step representations
- Focus on structure over detail
- Clear visual separation from other tiers

### 2. Step (Local Logic)
**Purpose**: Defines individual progression units within the story
**Responsibilities**:
- Activation conditions for story segments
- Completion criteria for story segments
- Local outcomes and triggers
- Linked cutscenes management
- World persistence and changes
- Local progression logic

**What it should NOT handle**:
- Direct scene execution details
- Character pathfinding
- Camera movements
- Specific animation sequences
- Real-time event scripting

**User Interface Characteristics**:
- Detailed configuration panels
- Condition and outcome management
- Cutscene linking tools
- Persistence settings
- Local logic workflow

### 3. Cutscene (Execution)
**Purpose**: Handles the concrete execution of story moments
**Responsibilities**:
- Dialogue presentation
- Character movements and pathfinding
- Camera control
- Animation sequences
- Player choices and responses
- Scene transitions
- Runtime execution flow

**What it should NOT handle**:
- Global story structure
- Cross-step dependencies
- Long-term progression logic
- World persistence beyond the scene
- High-level narrative decisions

**User Interface Characteristics**:
- Visual scripting interface
- Block-based programming
- Timeline controls
- Preview capabilities
- Execution debugging tools

## Key Principles

### Separation of Concerns
Each tier should focus exclusively on its designated responsibilities. Avoid cross-tier functionality that might confuse users about the appropriate level for specific tasks.

### Clear Boundaries
Users should immediately understand which tier they're working in and what types of elements belong there.

### Progressive Disclosure
Show higher-level concepts first (Global Story), then allow drilling down to more detail (Step), then to execution (Cutscene).

### Consistent Mental Model
Maintain consistent terminology and concepts across all tiers to help users build an accurate mental model of the narrative structure.

## Common Patterns

### Story Creation Workflow
1. **Global Story**: Define chapters and major story beats
2. **Step**: Configure individual progression units
3. **Cutscene**: Script the execution of story moments

### Example: Starter Selection Sequence
```
Global Story
├── Chapter: "Beginnings"
│   └── Step: "Choose Starter Pokemon"
│       └── Cutscene: "Starter Selection Event"
│           ├── Professor introduces starters
│           ├── Player chooses Fire/Water/Grass
│           ├── Specific dialogue per choice
│           └── Starter is added to party
```

## Visual Design Guidelines

### Global Story Tier
- Use vertical/hierarchical layouts
- Employ clear chapter dividers
- Show connections between steps
- Minimize detailed configuration options
- Focus on flow and structure

### Step Tier
- Provide detailed configuration panels
- Show local conditions and outcomes
- Link to associated cutscenes
- Display persistence settings
- Allow detailed logic configuration

### Cutscene Tier
- Use visual scripting interfaces
- Show execution timeline
- Provide preview capabilities
- Enable detailed action configuration
- Support conditional branching

## Maintenance Guidelines

### When Adding New Features
1. Determine which tier the feature belongs to
2. Ensure it doesn't overlap with other tiers
3. Design the UI to match the tier's characteristics
4. Maintain consistency with existing patterns

### When Refactoring
1. Preserve tier boundaries
2. Maintain user mental models
3. Update documentation accordingly
4. Consider impact on all three tiers

## Success Metrics

A well-implemented three-tier architecture should result in:
- Users understanding which tier to use for specific tasks
- Clear separation preventing feature creep between tiers
- Intuitive progression from macro to micro detail
- Reduced cognitive load by focusing on appropriate level of detail
- Easy maintenance and extension of functionality