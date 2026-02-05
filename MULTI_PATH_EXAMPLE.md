# Multi-Path Support Examples

The `cth_glob_*` and `cth_add_resources` functions now support multiple paths for convenience.

## Usage Examples

### Single Path (Backward Compatible)
```cmake
# Original usage - still works!
cth_glob_cpp(SOURCES "src")
cth_glob_cppm(MODULES "modules")
cth_add_resources(my_target "resources")
```

### Multiple Paths (New Feature)
```cmake
# Glob multiple directories in one call
cth_glob_cpp(ALL_SOURCES "src" "lib" "utils")

# Equivalent to:
# cth_glob_cpp(ALL_SOURCES "src")
# cth_glob_cpp(ALL_SOURCES "lib")
# cth_glob_cpp(ALL_SOURCES "utils")

# Glob modules from multiple locations
cth_glob_cppm(MODULES "modules" "internal_modules" "third_party_modules")

# Copy multiple resource directories
cth_add_resources(my_game "assets" "config" "shaders")
```

### Custom Patterns with Multiple Paths
```cmake
# Search for custom file patterns in multiple directories
cth_glob(PROTO_FILES "proto" "generated/proto" PATTERNS "*.proto")
cth_glob(CONFIG_FILES "config/dev" "config/prod" PATTERNS "*.json" "*.yaml")
```

### Real-World Example
```cmake
# Collect sources from multiple subdirectories
cth_glob_cpp(ENGINE_SOURCES 
    "engine/core"
    "engine/graphics"
    "engine/audio"
    "engine/physics"
)

# Collect public headers from different modules
cth_glob_cpp(PUBLIC_HEADERS
    "include/api"
    "include/utils"
    "include/types"
)

# Copy all resource types
cth_add_resources(my_game
    "resources/textures"
    "resources/sounds"
    "resources/models"
    "resources/fonts"
)
```

## Benefits

- **Less boilerplate**: One call instead of multiple
- **Cleaner CMakeLists.txt**: More readable project structure
- **Backward compatible**: Existing single-path calls still work
- **Flexible**: Mix and match as needed
