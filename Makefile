
# Check PDK
PDK_ROOT    := ${PDK_ROOT}
PDK_MAGICRC := $(PDK_ROOT)/sky130A/libs.tech/magic/sky130A.magicrc
ifeq ($(PDK_ROOT),)
  $(error "PDK_ROOT not in environment")
endif

# Optional color printing
ifneq ($(shell which tput),)
YELLOW := $(shell tput -Txterm setaf 3)
GREEN  := $(shell tput -Txterm setaf 2)
RESETC := $(shell tput -Txterm sgr0)
else
RED    :=
GREEN  :=
RESETC :=
endif

# target list (runtime populated)
LOGO_TARGETS :=

# Logo options
USE_LOGO ?= 1
LOGO_IMG_H ?= 64
LOGO_IMG_W ?= 64
LOGO_IMG_U ?= 1
LOGO_GDS := logo/gds/logo.gds
LOGO_MAG := logo/mag/logo.mag
LOGO_IMG := logo/img/logo.svg
LOGO_LEF := logo/lef/logo.lef

ifeq ($(USE_LOGO),1)
$(info USE_LOGO selected)

LOGO_TARGETS := $(LOGO_GDS) $(LOGO_LEF)

# Search logo inputs in this order.
# First one found is the type we process (INPUT>GDS/LEF).
# - LOGO_IMG: SVG logo input
# - LOGO_MAG: Magic logo input
# - LOGO_GDS: GDS-only logo input

#
# SVG RAW INPUT
#
ifneq ($(wildcard $(LOGO_IMG)),)

$(info $(YELLOW) LOGO_H: $(LOGO_IMG_H) $(RESETC))
$(info $(YELLOW) LOGO_W: $(LOGO_IMG_W) $(RESETC))
$(info $(YELLOW) LOGO_U: $(LOGO_IMG_U) $(RESETC))

$(LOGO_GDS): $(LOGO_IMG)
	$(info $(GREEN) IMG -> GDS $(RESETC))
	rsvg-convert $< -w $(LOGO_IMG_W) -h $(LOGO_IMG_H) -o $(patsubst %.svg,%.png,$<)
	./script/make_gds.py -u $(LOGO_IMG_U) -c logo -i $(patsubst %.svg,%.png,$<) -o $@
	$(info $(YELLOW) WARN: You may need to supply a LEF for this standalone SVG $(RESETC))

$(LOGO_LEF): $(LOGO_GDS)
	$(info $(GREEN) GDS -> LEF [Klayout] $(RESETC))
	klayout -zz -rd gds_path=$(LOGO_GDS) -rd out_file=$(LOGO_LEF) -rm ./script/gds2lef.py

clean_logo:
	rm -f $(LOGO_LEF) $(LOGO_GDS) logo/gds/logo.png

#
# MAG INPUT
#
else ifneq ($(wildcard $(LOGO_MAG)),)

$(LOGO_GDS): $(LOGO_MAG) | $(LOGO_LEF)
	$(info $(GREEN) MAG -> GDS $(RESETC))
	@echo "gds write \"$@\"" | magic -rcfile $(PDK_MAGICRC) -noconsole -dnull $<
	./script/gds_add_prb.py $@

$(LOGO_LEF): $(LOGO_MAG)
	$(info $(GREEN) MAG -> LEF $(RESETC))
	@echo "lef write \"$@\" -pinonly" | magic -rcfile $(PDK_MAGICRC) -noconsole -dnull $<

clean_logo:
	rm -f $(LOGO_LEF) $(LOGO_GDS)

#
# GDS RAW INPUT
#
else ifneq ($(wildcard $(LOGO_GDS)),)

$(LOGO_GDS):
	$(info $(GREEN) GDS (preproc) $(RESETC))
	./script/gds_add_prb.py $@
	$(info $(YELLOW) WARN: You may need to supply a LEF for this standalone GDS $(RESETC))

$(LOGO_LEF): $(LOGO_GDS)
	$(info $(GREEN) GDS -> LEF [Klayout] $(RESETC))
	klayout -zz -rd gds_path=$(LOGO_GDS) -rd out_file=$(LOGO_LEF) -rm ./script/gds2lef.py

clean_logo:
	rm -f $(LOGO_LEF)

# if no valid logo input asset found
else
	$(error $(YELLOW) you must supply a logo input file (logo/mag/logo.mag logo/gds/logo.gds or logo/img/logo.svg) $(RESETC))
endif	

endif # USE_LOGO
