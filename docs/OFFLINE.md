# Persistência e sincronização offline — issue #9

O PostgreSQL é a fonte definitiva dos dados. O SQLite do aparelho contém uma
cópia dos baralhos/cartões e uma fila de operações pendentes, separadas pelo ID
da conta. O arquivo `lume_offline.db` guarda cada estado e sua fila na mesma
transação, evitando mostrar uma alteração como salva sem persistir seu envio.

## O que funciona sem conexão

Depois de um login online bem-sucedido, é possível reabrir o aplicativo offline,
consultar os dados já baixados, criar/editar/excluir baralhos e cartões, mover ou
suspender cartões e registrar revisões comuns. Cada revisão conserva a data em
que foi feita, mesmo que seja enviada no dia seguinte. Estatísticas e outras
consultas mostram a última resposta salva; os resultados oficiais são atualizados
depois da sincronização. O banner informa o modo offline e as pendências.

O perfil local permite reabertura por até 29 dias após o login, sem estender o
prazo a cada abertura. O servidor mantém sessões de 30 dias e um retorno 401 na
restauração remove a sessão local. Não há login inicial offline nem validação
local de senhas. Logout remove token e perfil; pendências permanecem vinculadas
à conta e só voltam a ser enviadas após autenticar novamente nessa mesma conta.
Uma conta diferente nunca recebe essa fila.

## Reconexão e conflitos

O app tenta sincronizar ao abrir os baralhos, voltar ao primeiro plano, tocar em
Sincronizar e a cada 30 segundos enquanto está em execução. Não é um serviço de
sincronização com o aplicativo encerrado. A fila é enviada em ordem. Se o envio
falhar, a operação permanece no SQLite para a próxima tentativa.

Cada requisição tem `Idempotency-Key`. O backend grava a alteração e seu recibo
na mesma transação PostgreSQL. Uma resposta perdida pode ser reenviada sem criar
outro baralho ou contar a mesma revisão duas vezes. Um identificador reutilizado
com outro conteúdo é rejeitado. As rotas existentes mantêm validação e isolamento
por usuário; o recibo também pertence ao usuário.

A última alteração aceita pelo servidor prevalece para os campos enviados: não
há mesclagem automática de edições concorrentes do mesmo campo. Se um baralho ou
cartão tiver sido removido em outro aparelho, ou uma operação for rejeitada pela
validação, a fila para e continua salva localmente. O botão Resolver permite usar
os dados do servidor e descartar as pendências somente após confirmação. Se não
for possível baixar os dados do servidor, o descarte não acontece.

## Limites preservados

Cadastro, login inicial, alterações da conta, gerenciamento de desafios,
configurações e notificações exigem conexão para gravar. Revisões de desafios
exigem sincronização prévia e conexão para validar prazo/participação. As revisões
comuns funcionam offline. IA, biometria e repetição espaçada avançada continuam
protótipos, conforme o escopo do projeto.

## Verificação manual

1. Execute `docker compose up -d --build` e abra o APK atualizado na mesma rede
   da API configurada em `lib/data/services/api_service.dart`.
2. Entre e abra Baralhos para baixar os dados. Feche e reabra o app sem rede.
3. Crie um baralho/cartão, edite o cartão, faça uma revisão e confirme o aviso
   de alterações pendentes. Feche e reabra: os dados devem continuar presentes.
4. Reconecte e toque em Sincronizar (ou aguarde até 30 segundos com o app aberto).
   A fila deve esvaziar e os dados aparecer na API/segundo aparelho.
5. Saia e entre em outra conta: ela não deve visualizar dados nem pendências
   da conta anterior.
6. Para testar conflito, edite offline um baralho e remova o mesmo baralho em
   outro aparelho conectado. Reconecte: o aviso deve manter a edição local até
   confirmar Resolver > Descartar e atualizar.

## Testes automatizados

`flutter test` executa testes de persistência real no SQLite, reabertura,
isolamento entre contas e restauração offline da sessão. Para incluir o teste
integrado, inicie uma API apontando **apenas para um PostgreSQL descartável**, e
defina `LUME_TEST_API=http://127.0.0.1:52991/api` antes de executar o comando.
O teste cria e exclui sua própria conta. O CI configura esse ambiente isolado.

`npm test` em `server` usa `TEST_DATABASE_URL` com banco terminado em `_test`.
Inclui reenvios simultâneos, resposta perdida, isolamento, rollback e preservação
da data original de revisão. Nunca use o banco de usuários para esses testes.
