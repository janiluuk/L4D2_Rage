# Development

This section is for developers working on L4D2 Rage Edition.

## Guidelines

### [Agent Guidelines](agent-guidelines.md)
Coding standards, file organization, testing requirements, and contribution guidelines.

### [Plugin Integration](plugin-integration.md)
Guide for integrating new plugins as skills, including suggestions from the plugin corpus.

## Architecture

### Core Systems
- **Class System**: Manages player classes and their properties
- **Skill System**: Handles skill registration, activation, and cooldowns
- **Menu System**: Provides UI for class selection and settings
- **Deployment System**: Manages class-specific deployment actions

### Key Files
- `rage_survivor.sp` - Core plugin and class system
- `rage_class_skills.cfg` - Class skill configuration
- `include/rage/` - Core includes and utilities

## Contributing

1. Read the [Agent Guidelines](agent-guidelines.md)
2. Follow the coding standards
3. Write tests for new features
4. Update documentation
5. Submit pull requests

## Plugin Development

### Creating a New Skill
1. Create plugin file: `rage_survivor_plugin_<skillname>.sp`
2. Register skill: `RegisterRageSkill(PLUGIN_SKILL_NAME, 0)`
3. Implement `OnSpecialSkillUsed` callback
4. Add cooldown notifications: `CooldownNotify_Register()`
5. Assign to class in `rage_class_skills.cfg`

See [Plugin Integration](plugin-integration.md) for detailed examples.

## Code Quality

- Use `#pragma newdecls required`
- Clean up timers in `OnClientDisconnect`
- Clean up entities in `OnMapEnd` or `OnClientDisconnect`
- Use Rage validation helpers (`IsValidClient`, `KillTimerSafe`)
- Follow existing code style

## Related Documentation

- [Testing](../testing/)
- [Classes & Skills](../classes-skills/)

