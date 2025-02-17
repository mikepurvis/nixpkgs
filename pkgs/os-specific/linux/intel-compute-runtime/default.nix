{ lib
, stdenv
, fetchFromGitHub
, fetchpatch
, patchelf
, cmake
, pkg-config
, intel-gmmlib
, intel-graphics-compiler
, level-zero
, libva
}:

stdenv.mkDerivation rec {
  pname = "intel-compute-runtime";
  version = "22.49.25018.24";

  src = fetchFromGitHub {
    owner = "intel";
    repo = "compute-runtime";
    rev = version;
    sha256 = "sha256-/onHHIG5jWFObC8pSjpFMadjwaAN6vMNjAsj8/D3qNw=";
  };

  patches = [
    # fix compile with level-zero 1.9.4
    (fetchpatch {
      url = "https://github.com/intel/compute-runtime/commit/dce17d319f91b39806b2cd39b6eecd5c5cff2a68.patch";
      excludes = [ "manifests/manifest.yml" ];
      sha256 = "sha256-YGzS4LeNO8FO1GXowD2gARj0TL6tBFaeZJNLZOwSsWQ=";
    })
  ];

  nativeBuildInputs = [ cmake pkg-config ];

  buildInputs = [ intel-gmmlib intel-graphics-compiler libva level-zero ];

  cmakeFlags = [
    "-DSKIP_UNIT_TESTS=1"
    "-DIGC_DIR=${intel-graphics-compiler}"
    "-DOCL_ICD_VENDORDIR=${placeholder "out"}/etc/OpenCL/vendors"
    # The install script assumes this path is relative to CMAKE_INSTALL_PREFIX
    "-DCMAKE_INSTALL_LIBDIR=lib"
  ];

  outputs = [ "out" "drivers" ];

  postInstall = ''
    # Avoid clash with intel-ocl
    mv $out/etc/OpenCL/vendors/intel.icd $out/etc/OpenCL/vendors/intel-neo.icd

    mkdir -p $drivers/lib
    mv -t $drivers/lib $out/lib/libze_intel*
  '';

  postFixup = ''
    patchelf --set-rpath ${lib.makeLibraryPath [ intel-gmmlib intel-graphics-compiler libva stdenv.cc.cc.lib ]} \
      $out/lib/intel-opencl/libigdrcl.so
  '';

  meta = with lib; {
    homepage = "https://github.com/intel/compute-runtime";
    description = "Intel Graphics Compute Runtime for OpenCL. Replaces Beignet for Gen8 (Broadwell) and beyond";
    license = licenses.mit;
    platforms = [ "x86_64-linux" "aarch64-linux" ];
    maintainers = with maintainers; [ SuperSandro2000 ];
  };
}
