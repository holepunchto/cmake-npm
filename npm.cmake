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

  set(${result} ${npm})

  return(PROPAGATE ${result})
endfunction()

function(install_node_modules)
  find_npm(npm)

  execute_process(
    COMMAND ${npm} install
    WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
    OUTPUT_QUIET
    COMMAND_ERROR_IS_FATAL ANY
  )
endfunction()

function(resolve_node_module specifier result)
  set(dirname ${CMAKE_CURRENT_LIST_DIR})

  cmake_path(GET dirname ROOT_PATH root)

  while(TRUE)
    cmake_path(
      APPEND dirname node_modules ${specifier} package.json
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

  set(${result} ${specifier}-NOTFOUND)

  return(PROPAGATE ${result})
endfunction()
