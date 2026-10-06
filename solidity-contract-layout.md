# Solidity contract layout (standard order)

## File

1. SPDX license identifier  
2. `pragma`  
3. `import` statements  
4. File-level code (`interface`, `library`, `contract`, …)

## Inside a `contract`

1. Type declarations (`struct`, `enum`, …)  
2. State variables  
3. Events  
4. Errors (`error`)  
5. Modifiers  
6. Constructor  
7. `receive()` / `fallback()` (if used)  
8. External functions  
9. Public functions  
10. Internal functions  
11. Private functions  

Within each function group, put `view` and `pure` functions last.
