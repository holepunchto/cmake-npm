function(install_node_modules)
  execute_process(
    COMMAND npm install
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

      cmake_path(NATIVE_PATH ${result} NORMALIZE ${result})

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
