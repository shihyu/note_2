# CMAKE generated file: DO NOT EDIT!
# Generated by "Unix Makefiles" Generator, CMake Version 3.26

# Delete rule output on recipe failure.
.DELETE_ON_ERROR:

#=============================================================================
# Special targets provided by cmake.

# Disable implicit rules so canonical targets will work.
.SUFFIXES:

# Disable VCS-based implicit rules.
% : %,v

# Disable VCS-based implicit rules.
% : RCS/%

# Disable VCS-based implicit rules.
% : RCS/%,v

# Disable VCS-based implicit rules.
% : SCCS/s.%

# Disable VCS-based implicit rules.
% : s.%

.SUFFIXES: .hpux_make_needs_suffix_list

# Command-line flag to silence nested $(MAKE).
$(VERBOSE)MAKESILENT = -s

#Suppress display of executed commands.
$(VERBOSE).SILENT:

# A target that is always out of date.
cmake_force:
.PHONY : cmake_force

#=============================================================================
# Set environment variables for the build.

# The shell in which to execute make rules.
SHELL = /bin/sh

# The CMake executable.
CMAKE_COMMAND = /home/shihyu/.mybin/cmake/bin/cmake

# The command to remove a file.
RM = /home/shihyu/.mybin/cmake/bin/cmake -E rm -f

# Escaping for special characters.
EQUALS = =

# The top-level source directory on which CMake was run.
CMAKE_SOURCE_DIR = /media/shihyu/ssd1/github/jason_note/src/c++/data/CppTrader/CppTrader_modify

# The top-level build directory on which CMake was run.
CMAKE_BINARY_DIR = /media/shihyu/ssd1/github/jason_note/src/c++/data/CppTrader/CppTrader_modify/temp

# Include any dependencies generated for this target.
include func_tracker/CMakeFiles/func_tracker.dir/depend.make
# Include any dependencies generated by the compiler for this target.
include func_tracker/CMakeFiles/func_tracker.dir/compiler_depend.make

# Include the progress variables for this target.
include func_tracker/CMakeFiles/func_tracker.dir/progress.make

# Include the compile flags for this target's objects.
include func_tracker/CMakeFiles/func_tracker.dir/flags.make

func_tracker/CMakeFiles/func_tracker.dir/FuncTracker.cpp.o: func_tracker/CMakeFiles/func_tracker.dir/flags.make
func_tracker/CMakeFiles/func_tracker.dir/FuncTracker.cpp.o: /media/shihyu/ssd1/github/jason_note/src/c++/data/CppTrader/CppTrader_modify/func_tracker/FuncTracker.cpp
func_tracker/CMakeFiles/func_tracker.dir/FuncTracker.cpp.o: func_tracker/CMakeFiles/func_tracker.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/media/shihyu/ssd1/github/jason_note/src/c++/data/CppTrader/CppTrader_modify/temp/CMakeFiles --progress-num=$(CMAKE_PROGRESS_1) "Building CXX object func_tracker/CMakeFiles/func_tracker.dir/FuncTracker.cpp.o"
	cd /media/shihyu/ssd1/github/jason_note/src/c++/data/CppTrader/CppTrader_modify/temp/func_tracker && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -MD -MT func_tracker/CMakeFiles/func_tracker.dir/FuncTracker.cpp.o -MF CMakeFiles/func_tracker.dir/FuncTracker.cpp.o.d -o CMakeFiles/func_tracker.dir/FuncTracker.cpp.o -c /media/shihyu/ssd1/github/jason_note/src/c++/data/CppTrader/CppTrader_modify/func_tracker/FuncTracker.cpp

func_tracker/CMakeFiles/func_tracker.dir/FuncTracker.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/func_tracker.dir/FuncTracker.cpp.i"
	cd /media/shihyu/ssd1/github/jason_note/src/c++/data/CppTrader/CppTrader_modify/temp/func_tracker && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /media/shihyu/ssd1/github/jason_note/src/c++/data/CppTrader/CppTrader_modify/func_tracker/FuncTracker.cpp > CMakeFiles/func_tracker.dir/FuncTracker.cpp.i

func_tracker/CMakeFiles/func_tracker.dir/FuncTracker.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/func_tracker.dir/FuncTracker.cpp.s"
	cd /media/shihyu/ssd1/github/jason_note/src/c++/data/CppTrader/CppTrader_modify/temp/func_tracker && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /media/shihyu/ssd1/github/jason_note/src/c++/data/CppTrader/CppTrader_modify/func_tracker/FuncTracker.cpp -o CMakeFiles/func_tracker.dir/FuncTracker.cpp.s

# Object files for target func_tracker
func_tracker_OBJECTS = \
"CMakeFiles/func_tracker.dir/FuncTracker.cpp.o"

# External object files for target func_tracker
func_tracker_EXTERNAL_OBJECTS =

func_tracker/libfunc_tracker.a: func_tracker/CMakeFiles/func_tracker.dir/FuncTracker.cpp.o
func_tracker/libfunc_tracker.a: func_tracker/CMakeFiles/func_tracker.dir/build.make
func_tracker/libfunc_tracker.a: func_tracker/CMakeFiles/func_tracker.dir/link.txt
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --bold --progress-dir=/media/shihyu/ssd1/github/jason_note/src/c++/data/CppTrader/CppTrader_modify/temp/CMakeFiles --progress-num=$(CMAKE_PROGRESS_2) "Linking CXX static library libfunc_tracker.a"
	cd /media/shihyu/ssd1/github/jason_note/src/c++/data/CppTrader/CppTrader_modify/temp/func_tracker && $(CMAKE_COMMAND) -P CMakeFiles/func_tracker.dir/cmake_clean_target.cmake
	cd /media/shihyu/ssd1/github/jason_note/src/c++/data/CppTrader/CppTrader_modify/temp/func_tracker && $(CMAKE_COMMAND) -E cmake_link_script CMakeFiles/func_tracker.dir/link.txt --verbose=$(VERBOSE)

# Rule to build all files generated by this target.
func_tracker/CMakeFiles/func_tracker.dir/build: func_tracker/libfunc_tracker.a
.PHONY : func_tracker/CMakeFiles/func_tracker.dir/build

func_tracker/CMakeFiles/func_tracker.dir/clean:
	cd /media/shihyu/ssd1/github/jason_note/src/c++/data/CppTrader/CppTrader_modify/temp/func_tracker && $(CMAKE_COMMAND) -P CMakeFiles/func_tracker.dir/cmake_clean.cmake
.PHONY : func_tracker/CMakeFiles/func_tracker.dir/clean

func_tracker/CMakeFiles/func_tracker.dir/depend:
	cd /media/shihyu/ssd1/github/jason_note/src/c++/data/CppTrader/CppTrader_modify/temp && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /media/shihyu/ssd1/github/jason_note/src/c++/data/CppTrader/CppTrader_modify /media/shihyu/ssd1/github/jason_note/src/c++/data/CppTrader/CppTrader_modify/func_tracker /media/shihyu/ssd1/github/jason_note/src/c++/data/CppTrader/CppTrader_modify/temp /media/shihyu/ssd1/github/jason_note/src/c++/data/CppTrader/CppTrader_modify/temp/func_tracker /media/shihyu/ssd1/github/jason_note/src/c++/data/CppTrader/CppTrader_modify/temp/func_tracker/CMakeFiles/func_tracker.dir/DependInfo.cmake --color=$(COLOR)
.PHONY : func_tracker/CMakeFiles/func_tracker.dir/depend
