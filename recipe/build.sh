BUILD_TYPE="Release"
CXXFLAGS="${CXXFLAGS//-march=nocona}"
CXXFLAGS="${CXXFLAGS//-mtune=haswell}"

export CXX=$(basename ${CXX})

if [[ ! -z "$mpi" && "$mpi" != "nompi" ]]; then
  MPI_SUPPORT=ON
else
  MPI_SUPPORT=OFF
fi

if [[ "$CONDA_BUILD_CROSS_COMPILATION" == "1" ]]; then
  # This is only used by open-mpi's mpicc
  # ignored in other cases
  export OMPI_CC="$CC"
  export OMPI_CXX="$CXX"
  export OMPI_FC="$FC"
  export OPAL_PREFIX="$PREFIX"
fi

if [[ ! -z "$mpi" && "$mpi" == "openmpi" ]]; then
  export CXX="mpicxx"
fi

# configure
cmake ${CMAKE_ARGS} \
  -H${SRC_DIR} \
  -Bbuild \
  -GNinja \
  -DCMAKE_INSTALL_PREFIX=${PREFIX} \
  -DCMAKE_BUILD_TYPE=${BUILD_TYPE} \
  -DENABLE_OPENMP=ON \
  -DENABLE_ARCH_FLAGS=OFF \
  -DENABLE_MPI=${MPI_SUPPORT} \
  -DCMAKE_CXX_COMPILER="${CXX}" \
  -DCMAKE_INSTALL_LIBDIR="lib" \
  -DBUILD_STATIC_LIBS=False \
  -DENABLE_TESTS=True

# build
cd build
cmake --build . -- -j${CPU_COUNT} -v -d stats

# test
if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" != "1" || "${CROSSCOMPILING_EMULATOR}" != "" ]]; then
  ctest -j${CPU_COUNT} --output-on-failure --verbose
fi

# install
cmake --build . --target install -- -j${CPU_COUNT}
