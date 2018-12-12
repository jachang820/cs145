load_pkg = function(pkg) {
	if (!nzchar(system.file(package=pkg)) {
		install.packages(pkg)
	}
	library(pkg)
}

load_pkg(dplyr)