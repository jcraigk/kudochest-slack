.PHONY : build clean spec start stop up services

all : build up

build :
	docker compose build

clean :
	docker compose down --remove-orphans
	docker compose rm
	docker image prune
	docker volume prune

dev: services
	overmind start -f Procfile.dev

cleanforce:
	docker compose down -v
	docker image prune -af
	docker volume prune -f

services :
	brew services stop postgresql
	docker compose up -d pg redis

spec :
	docker compose up -d pg redis
	docker compose run --rm app bundle exec rails db:reset RAILS_ENV=test
	docker compose run --rm app bundle exec rspec $(file)

rubocop :
	docker compose run --rm app bundle exec rubocop

start :
	docker compose up -d

stop :
	docker compose stop

up :
	docker compose up

restart : stop start

rebuild : stop build start
