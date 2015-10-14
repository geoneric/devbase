include(CheckCXXSourceRuns)

set(CMAKE_REQUIRED_INCLUDES ${GDAL_INCLUDE_DIR})

if(NOT WIN32)
    set(_ADDITIONAL_LIBS "dl")
endif()
set(CMAKE_REQUIRED_LIBRARIES ${GDAL_LIBRARY} ${_ADDITIONAL_LIBS})


# Check whether the GDal lib is compiled with support for OGR.
# If so, this code defines DEVBASE_GDAL_LIBRARY_HAS_OGR_SUPPORT.
check_cxx_source_runs("
    #include <gdal_priv.h>
    #include <ogrsf_frmts.h>

    int main(int argc, char** argv) {
        // This works with a sound GDal. If this fails, all bets are off.
        GDALDriverManager const& gdalManager(*GetGDALDriverManager());

        // This doesn't work if GDal does not have OGR support.
        OGRSFDriverRegistrar& ogrManager(*OGRSFDriverRegistrar::GetRegistrar());

        return 0;
    }"
    DEVBASE_GDAL_LIBRARY_HAS_OGR_SUPPORT
)
