COMPOSE ?= docker compose

up:
	$(COMPOSE) up -d

down:
	$(COMPOSE) down

clean:
	$(COMPOSE) down -v

certs:
	./scripts/generate_certs.sh

test-recon:
	$(COMPOSE) exec kali /scripts/test_recon.sh

test-bruteforce:
	$(COMPOSE) exec kali /scripts/test_bruteforce.sh

test-sqli:
	$(COMPOSE) exec kali /scripts/test_sqli_xss.sh

test-tls:
	$(COMPOSE) exec kali /scripts/test_tls.sh

test-segmentation:
	$(COMPOSE) exec nginx-waf /scripts/test_segmentation.sh
