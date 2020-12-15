# 1.1.1 - December 15, 2020
- Update rake
- Fix Encoding::UndefinedConversionError (#8)

# 1.1.0 - September 13, 2020
- Use 32-bit integers for variable and thread references (#6)
 
# 1.0.0 - February 9, 2020
- Refactor server and target process communication
- STDIO server support
- Fix zombie process bugs
- Sort variables alphabetically

# 0.8.1 - November 14, 2019
- Header name conflict in MacOS (#4)

# 0.8.0 - November 9, 2019
- Multiple frames
- Flush output on disconnect
- Use Ruby debug inspector for stack frames
- Faster line processing
- Monitor disables GC

# 0.7.1 - October 13, 2019
- Debugger sets program name

# 0.7.0 - October 12, 2019
- Conditional breakpoints
- Graceful shutdown (#2)

# 0.6.2 - September 10, 2019
- Monitor processes all new threads
- Discard buggy output redirection

# 0.6.1 - September 7, 2019
- Ignore nilable paths in thread events

# 0.6.0 - August 26, 2019
- Evaluate in REPL

# 0.5.0 - August 20, 2019
- Monitor stores paths as C strings
- Fixed malloc size for normalized paths
- Fixed table insertion before existing items

# 0.4.0 - August 19. 2019
- Breakpoints use C implementation of hash tables
- Simplified entry point detection

# 0.3.5 - August 16, 2019
- Variables message checks for null frames

# 0.3.4 - August 12, 2019
- Monitor normalizes paths.

# 0.3.3 - August 12, 2019
- Remove RB_NIL_P for backwards compatibility

# 0.3.2 - August 11, 2019
- Unnecessary thread in Backport.run

# 0.3.1 - August 10. 2019
- Require Ruby >= 2.2

# 0.3.0 - August 9. 2019
- Synchronized events
- Handle multiple paused threads
- Isolate the Backport machine

# 0.2.0 - August 7, 2019
- Find external programs
- Improved stdout/stderr redirects
- Individual thread control

# 0.1.0 - August 5, 2019
- First release
