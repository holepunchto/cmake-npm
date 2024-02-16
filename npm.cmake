function(find_npm result)
  if(WIN32)
    find_program(
      npm
      NAMES npm.cmd npm
      REQUIRED
    )
  else()
    find_program(
      npm
      NAMES npm
      REQUIRED
    )
  endif()

  set(${result} "${npm}")

  return(PROPAGATE ${result})
endfunction()

function(install_node_modules)
  cmake_parse_arguments(
    PARSE_ARGV 0 ARGV "LOCKFILE" "WORKING_DIRECTORY" ""
  )

  if(ARGV_WORKING_DIRECTORY)
    cmake_path(ABSOLUTE_PATH ARGV_WORKING_DIRECTORY BASE_DIRECTORY "${CMAKE_CURRENT_LIST_DIR}" NORMALIZE)
  else()
    set(ARGV_WORKING_DIRECTORY "${CMAKE_CURRENT_LIST_DIR}")
  endif()

  find_npm(npm)

  if(ARGV_LOCKFILE)
    set(command install-clean)
  else()
    set(command install)
  endif()

  execute_process(
    COMMAND "${npm}" ${command}
    WORKING_DIRECTORY "${ARGV_WORKING_DIRECTORY}"
    OUTPUT_QUIET
    COMMAND_ERROR_IS_FATAL ANY
  )

  cmake_path(APPEND ARGV_WORKING_DIRECTORY package.json OUTPUT_VARIABLE package_path)

  cmake_path(APPEND ARGV_WORKING_DIRECTORY package-lock.json OUTPUT_VARIABLE package_lock_path)

  set_property(
    DIRECTORY
    APPEND
    PROPERTY CMAKE_CONFIGURE_DEPENDS
      "${package_path}"
      "${package_lock_path}"
  )
endfunction()

function(resolve_node_module specifier result)
  cmake_parse_arguments(
    PARSE_ARGV 0 ARGV "" "WORKING_DIRECTORY" ""
  )

  if(ARGV_WORKING_DIRECTORY)
    cmake_path(ABSOLUTE_PATH ARGV_WORKING_DIRECTORY BASE_DIRECTORY "${CMAKE_CURRENT_LIST_DIR}" NORMALIZE)
  else()
    set(ARGV_WORKING_DIRECTORY "${CMAKE_CURRENT_LIST_DIR}")
  endif()

  set(dirname "${ARGV_WORKING_DIRECTORY}")

  cmake_path(GET dirname ROOT_PATH root)

  while(TRUE)
    cmake_path(
      APPEND dirname node_modules "${specifier}" package.json
      OUTPUT_VARIABLE target
    )

    if(EXISTS ${target})
      cmake_path(GET target PARENT_PATH ${result})

      return(PROPAGATE ${result})
    endif()

    if(dirname PATH_EQUAL root)
      break()
    endif()

    cmake_path(GET dirname PARENT_PATH dirname)
  endwhile()

  set(${result} "${specifier}-NOTFOUND")

  return(PROPAGATE ${result})
endfunction()
