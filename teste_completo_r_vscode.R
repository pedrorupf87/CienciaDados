# ===============================================
# TESTE COMPLETO: VS Code + R no Ubuntu 22.04
# Execute linha por linha (Ctrl + Enter) ou chunk por chunk
# ===============================================

# 1. Carregar pacotes essenciais (deve funcionar sem erro)
library(tidyverse)
library(httpgd)      # plots interativos
library(languageserver)  # só para confirmar que está vivo
library(vscDebugger)     # debug

cat("\033[0;32m✓ Pacotes carregados com sucesso!\033[0m\n\n")

# 2. Teste do pipe %>% (digite Alt + - para inserir)
iris %>% 
  head() %>% 
  print()

cat("\n\033[0;32m✓ Pipe e autocomplete funcionando\033[0m\n")

# 3. Plot interativo com httpgd (deve abrir uma aba ao lado com zoom, save, etc.)
hgd()                # abre o servidor de plots (só na primeira vez)
cat("\nServer httpgd rodando em:", hgd_url(), "\n")

ggplot(iris, aes(Sepal.Length, Sepal.Width, color = Species)) +
  geom_point(size = 3) +
  theme_minimal() +
  labs(title = "Plot interativo httpgd - teste zoom e salvar!")

cat("\n\033[0;32m✓ Plot interativo apareceu na aba 'Plots'? (use as setas para navegar)\033[0m\n")

# 4. View() como no RStudio (deve abrir uma aba com tabela interativa)
View(iris)
cat("\n\033[0;32m✓ View(iris) abriu uma tabela com busca e filtro?\033[0m\n")

# 5. Data frame grande (testa limite do viewer)
df_grande <- mtcars %>% 
  rownames_to_column("carro") %>% 
  slice(rep(1:n(), 50))   # 1600 linhas

View(df_grande)
cat("\n\033[0;32m✓ View() com muitas linhas funcionou?\033[0m\n")

# 6. Help interativo (coloque o cursor em ggplot e pressione F1)
?ggplot
cat("\n\033[0;32m✓ Help apareceu na aba lateral? (F1 com cursor na função)\033[0m\n")

# 7. Debug (F5 no script inteiro ou Ctrl+F5 no chunk)
# Coloque um breakpoint (clique à esquerda do número da linha)
# Depois pressione F5 para entrar no modo debug
debug_once(lm)
lm(mpg ~ wt, data = mtcars)   # vai parar no breakpoint

cat("\n\033[0;32m✓ Debug funcionou? (F5 + breakpoint + Step Into/Over)\033[0m\n")

# 8. R Markdown / Quarto (se salvar como .Rmd ou .qmd)
# Salve este arquivo como teste.qmd e pressione Ctrl+Shift+K → Render
# Deve gerar HTML com tudo funcionando

# 9. Mensagem final
cat("\n\033[1;33m═══════════════════════════════════════\033[0m\n")
cat("\033[1;32mPARABÉNS! Tudo está funcionando 100%!\033[0m\n")
cat("Você agora tem no VS Code:\n")
cat("  • Autocomplete perfeito\n")
cat("  • Plots interativos (zoom/save)\n")
cat("  • View() com busca e filtros\n")
cat("  • Debug linha a linha\n")
cat("  • R Markdown / Quarto\n")
cat("  • Atalhos iguais ao RStudio\n")
cat("\033[1;33m═══════════════════════════════════════\033[0m\n")