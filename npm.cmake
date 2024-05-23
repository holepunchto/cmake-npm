function(find_npm result)
  if(CMAKE_HOST_WIN32)
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
    PARSE_ARGV 2 ARGV "" "WORKING_DIRECTORY" ""
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

function(list_node_modules result)
  cmake_parse_arguments(
    PARSE_ARGV 1 ARGV "DEVELOPMENT" "WORKING_DIRECTORY" ""
  )

  if(ARGV_WORKING_DIRECTORY)
    cmake_path(ABSOLUTE_PATH ARGV_WORKING_DIRECTORY BASE_DIRECTORY "${CMAKE_CURRENT_LIST_DIR}" NORMALIZE)
  else()
    set(ARGV_WORKING_DIRECTORY "${CMAKE_CURRENT_LIST_DIR}")
  endif()

  if(ARGV_DEVELOPMENT)
    set(DEVELOPMENT DEVELOPMENT)
  endif()

  cmake_path(APPEND ARGV_WORKING_DIRECTORY package.json OUTPUT_VARIABLE package_path)

  file(READ "${package_path}" package)

  list(APPEND properties dependencies optionalDependencies)

  if(ARGV_DEVELOPMENT)
    list(APPEND properties devDependencies)
  endif()

  foreach(property ${properties})
    string(JSON dependencies ERROR_VARIABLE error GET "${package}" ${property})

    if(error MATCHES "NOTFOUND")
      string(JSON len LENGTH "${dependencies}")

      foreach(i RANGE ${len})
        if(NOT i EQUAL len)
          string(JSON specifier MEMBER "${dependencies}" ${i})

          resolve_node_module(${specifier} resolved WORKING_DIRECTORY ${ARGV_WORKING_DIRECTORY})

          if("${resolved}" MATCHES "NOTFOUND" OR "${resolved}" IN_LIST ${result})
            continue()
          endif()

          list(APPEND ${result} "${resolved}")

          list_node_modules(${result} WORKING_DIRECTORY ${resolved} ${DEVELOPMENT})
        endif()
      endforeach()
    endif()
  endforeach()

  return(PROPAGATE ${result})
endfunction()
