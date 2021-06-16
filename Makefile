TAG      := $(shell git log -1 --pretty=%H || echo MISSING )
NAME     := rdt12/paws
IMG      := $(NAME):$(TAG)
LTST     := $(NAME):latest

all: image

print-%  : ; @echo $* = $($*)

image: Dockerfile
	@if [ ! -z "$$(git status --porcelain)" ]; then echo "Directory is not clean. Commit your changes."; exit 1; fi
	docker build --pull -f $< -t $(IMG) .
	docker tag $(IMG) $(LTST)
