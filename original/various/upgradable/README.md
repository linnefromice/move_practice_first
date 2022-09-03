# upgradable

```bash
aptos init
# update Move.toml
aptos move compile
aptos move publish

ADDR=(deployed address)
aptos move run --function-id ${ADDR}::point::initialize

# first
aptos move run --function-id ${ADDR}::point::add_point --args u64:5
aptos move run --function-id ${ADDR}::point::add_point --args u64:6
aptos account list
# upgrade
## update point.move
aptos move compile
aptos move publish
# second
aptos move run --function-id ${ADDR}::point::initialize_index
aptos move run --function-id ${ADDR}::point::add_point --args u64:5
aptos move run --function-id ${ADDR}::point::add_point --args u64:6
aptos account list
```