cmake_minimum_required(VERSION 3.12)
project(hellocmake LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
if (NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()

add_executable(main main.cpp)

find_package(OpenMP)
if (TARGET OpenMP::OpenMP_CXX)
    target_link_libraries(main PUBLIC OpenMP::OpenMP_CXX)
else()
    message(WARNING "OpenMP not found")
endif()

#find_package(TBB)
#if (TARGET TBB::tbb)
    #target_link_libraries(main PUBLIC TBB::tbb)
#else()
    #message(WARNING "TBB not found")
#endif()
