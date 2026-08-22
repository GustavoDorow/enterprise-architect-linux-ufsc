# Enterprise Architect 14 no Linux para a UFSC

Este projeto instala o Sparx Systems Enterprise Architect 14.1.1429 no Linux por meio do Wine e configura o servidor de licenças acadêmicas da UFSC.

A instalação foi testada no Omarchy 4.0 com Wine 11.15. O instalador MSI, os componentes Jet e DAO e as bibliotecas XML nativas funcionaram corretamente. Também foi possível abrir um modelo `.eap` e obter a licença `EA Academic` pela VPN da UFSC.

O programa continua sendo a versão para Windows. O Wine cria um ambiente isolado somente para o Enterprise Architect, sem alterar outros aplicativos Windows que já estejam instalados no mesmo usuário Linux.

## Arquivos necessários

O repositório não distribui o instalador proprietário nem a configuração do servidor de licenças. Obtenha estes dois arquivos por um canal autorizado da UFSC e coloque-os na mesma pasta de `install-linux.sh`:

```text
enterprise-architect-linux-ufsc/
├── install-linux.sh
├── KeyStore.reg
└── SetupFull.msi
```

Função de cada arquivo:

- `SetupFull.msi` instala o Enterprise Architect 14.1 de 32 bits.
- `KeyStore.reg` configura o cliente para usar o servidor flutuante de licenças da UFSC.
- `install-linux.sh` instala as dependências, cria o ambiente Wine e integra o aplicativo ao desktop Linux.

O script confere o SHA-256 dos dois arquivos fornecidos. Se algum deles estiver incompleto ou for diferente da versão testada, a instalação para antes de criar um ambiente Wine quebrado.

Não publique `SetupFull.msi` ou `KeyStore.reg` em sites, repositórios Git, fóruns ou grupos abertos. Use apenas meios aprovados pela UFSC.

## Instalação

Abra um terminal na pasta do projeto e execute:

```bash
chmod +x install-linux.sh
./install-linux.sh
```

Execute o script como seu usuário normal, sem colocar `sudo` antes dele. O gerenciador de pacotes pedirá sua senha quando precisar instalar dependências do sistema.

O script faz o seguinte:

1. Instala Wine, Winetricks, UnixODBC e 7-Zip. No Arch Linux, também instala Wine Gecko e Wine Mono.
2. Cria um prefixo Wine separado em `~/.local/share/enterprise-architect-14/prefix`.
3. Instala o MSI e importa a configuração de licença.
4. Instala as bibliotecas MSXML3 e MSXML4 necessárias para o EA 14.
5. Cria o comando `~/.local/bin/enterprise-architect`.
6. Adiciona o Enterprise Architect 14 ao menu de aplicativos.
7. Associa arquivos `.eap`, `.eapx` e `.feap` ao aplicativo.

A instalação ocupa aproximadamente 1,5 GB. Na primeira execução, o Winetricks também baixa um pacote de aproximadamente 903 MB do Windows 7 para extrair a biblioteca MSXML3 verificada. O download fica em `~/.cache/winetricks` e pode ser apagado depois que o EA estiver funcionando.

## Compatibilidade com distribuições Linux

O script automatiza a instalação de dependências nestas famílias de distribuições x86-64:

- Omarchy, Arch Linux, EndeavourOS, CachyOS e outros sistemas com `pacman`
- Debian e Ubuntu com `apt-get`
- Fedora com `dnf`

Em outra distribuição, incluindo openSUSE, o script continua se os comandos `wine`, `wineserver`, `winetricks` e `7z` já estiverem instalados. Caso contrário, ele para e informa as dependências necessárias.

O Enterprise Architect 14 é um programa Windows de 32 bits. Portanto, o Wine precisa ter suporte a aplicativos de 32 bits. Este instalador não aceita sistemas ARM, como Raspberry Pi e alguns Chromebooks.

Somente a combinação Omarchy 4.0 e Wine 11.15 foi testada diretamente. Os caminhos para Debian, Ubuntu e Fedora usam os gerenciadores de pacotes padrão, mas ainda precisam de testes em máquinas separadas. Versões diferentes do Wine podem apresentar comportamentos diferentes.

## Conexão com a rede da UFSC

A instalação pode ser feita fora da rede universitária, mas a licença flutuante precisa da rede UFSC. Durante os testes, o servidor de licenças não resolveu fora da VPN. Com a VPN conectada, o EA obteve a licença acadêmica corretamente.

Antes de abrir o programa, conecte-se à `redeUFSC` no campus ou à VPN da UFSC. A universidade usa IKEv2 e mantém as orientações na [página oficial do serviço de VPN](https://setic.ufsc.br/servicos/acesso-a-redeufsc/servico-de-vpn-virtual-private-network/).

O nome de usuário da VPN é o idUFSC completo, terminado em `@ufsc.br`. Não use o endereço terminado em `@grad.ufsc.br` ou `@posgrad.ufsc.br`.

### Configurar a VPN no Omarchy ou Arch Linux

Instale o complemento IKEv2 do NetworkManager:

```bash
omarchy pkg add networkmanager-strongswan
```

Em um Arch Linux sem Omarchy, use:

```bash
sudo pacman -S --needed networkmanager-strongswan
```

Crie a conexão, substituindo `SEU_ID` pelo seu idUFSC:

```bash
nmcli connection add \
  type vpn \
  ifname -- \
  vpn-type strongswan \
  connection.id 'UFSC IKEv2' \
  connection.autoconnect no \
  vpn.data 'address=vpn.ufsc.br, encap=no, esp=aes128gcm16, ipcomp=no, method=eap, user=SEU_ID@ufsc.br, virtual=yes, proposal=no,password-flags=0'
```

Ative `UFSC IKEv2` pelo menu de rede e informe sua senha do idUFSC.

### Testar o acesso ao servidor de licenças

Execute:

```bash
getent hosts licenciador2012.setic.ufsc.br
```

O comando deve mostrar um endereço IP. Se não houver saída, a máquina ainda não consegue encontrar o servidor. Verifique a conexão com a VPN antes de alterar o Wine ou reinstalar o programa.

## Abrir o Enterprise Architect

Procure por `Enterprise Architect 14` no menu de aplicativos ou execute:

```bash
enterprise-architect
```

Se `~/.local/bin` não estiver no `PATH` do seu shell, use o caminho completo:

```bash
~/.local/bin/enterprise-architect
```

Para abrir um modelo existente pelo terminal:

```bash
enterprise-architect /caminho/completo/modelo.eap
```

Também é possível abrir arquivos `.eap`, `.eapx` e `.feap` pelo gerenciador de arquivos. Se o Linux perguntar qual programa usar, escolha Enterprise Architect 14.

Salve seus trabalhos em uma pasta normal do Linux, como `~/Documentos`. O Wine mostra o sistema de arquivos Linux pela unidade `Z:`. Por exemplo, `/home/aluno/Documentos/modelo.eap` aparece dentro do EA como `Z:\home\aluno\Documentos\modelo.eap`.

## Conferir a configuração da licença

Execute:

```bash
WINEPREFIX="$HOME/.local/share/enterprise-architect-14/prefix" \
  wine reg query 'HKCU\Software\Sparx Systems\EA400\EA\OPTIONS' /v SSKSAddress
```

O resultado deve conter:

```text
ssks://licenciador2012.setic.ufsc.br
```

Se a configuração estiver ausente, importe novamente o arquivo fornecido pela UFSC:

```bash
WINEPREFIX="$HOME/.local/share/enterprise-architect-14/prefix" \
  wine regedit /s "$(winepath -w "$PWD/KeyStore.reg")"
```

## Solução de problemas

### A licença não está disponível

Execute primeiro o teste de acesso ao servidor. Sem resultado no `getent`, conecte-se à rede UFSC ou à VPN.

Se o servidor resolver, mas o EA continuar sem licença, o conjunto de licenças pode estar esgotado ou o serviço pode estar indisponível. Abra um chamado no [portal de atendimento da SeTIC](https://atendimento.setic.ufsc.br/).

### O aplicativo não abre

Inicie o EA com as mensagens de erro do Wine habilitadas:

```bash
WINEDEBUG=err+all enterprise-architect 2>&1 | tee ea-wine-errors.log
```

Linhas com `fixme` são anotações internas do Wine e não indicam necessariamente uma falha. Procure linhas com `err:` próximas ao fim do arquivo.

Um erro sobre `libodbc.so` indica que o UnixODBC está ausente. No Arch Linux ou Omarchy, instale com:

```bash
omarchy pkg add unixodbc
```

### Aparece "Error creating XML Parser"

Esse erro indica que a biblioteca XML nativa de 32 bits não foi registrada corretamente. Execute novamente o instalador atualizado:

```bash
./install-linux.sh
```

O MSI do EA 14 pode fazer o instalador antigo da Microsoft para MSXML4 retornar o código 67. Nesse caso, o script extrai a DLL de 32 bits do download verificado pelo Winetricks e registra a biblioteca diretamente.

### O texto está muito pequeno ou muito grande

Abra a configuração do Wine somente para este aplicativo:

```bash
WINEPREFIX="$HOME/.local/share/enterprise-architect-14/prefix" winecfg
```

Na aba `Graphics`, ajuste a resolução em DPI. Em telas de alta densidade, teste 120 ou 144 DPI.

### Um modelo não abre pelo gerenciador de arquivos

Abra o EA, selecione `File > Open Project`, escolha a unidade `Z:` e navegue até sua pasta pessoal do Linux. Outra opção é usar o comando `enterprise-architect /caminho/modelo.eap`.

## Reparar ou reinstalar

Execute o script novamente:

```bash
./install-linux.sh
```

O Windows Installer reparará a instalação existente. Não apague o prefixo antes de copiar qualquer modelo salvo dentro dele.

## Remover

Antes de remover, confira se existem modelos dentro de:

```text
~/.local/share/enterprise-architect-14/prefix/drive_c/
```

Depois, envie estes caminhos para a lixeira pelo gerenciador de arquivos:

```text
~/.local/share/enterprise-architect-14/
~/.local/share/applications/enterprise-architect.desktop
~/.local/share/mime/packages/enterprise-architect.xml
~/.local/bin/enterprise-architect
```

O Wine é instalado como pacote compartilhado do sistema. Mantenha-o se outro aplicativo Windows depender dele.

## Limites e licença

Enterprise Architect é um produto da Sparx Systems. Este projeto não distribui, substitui nem concede uma licença do software. O acesso depende de vínculo válido, autorização da UFSC, disponibilidade do servidor e cumprimento dos termos aplicáveis.

O procedimento Linux recomendado pela Sparx também usa Wine, Winetricks, MSXML3 e MSXML4. Consulte a [documentação oficial do Enterprise Architect no Linux](https://sparxsystems.com/enterprise_architect_user_guide/17.2/getting_started/enterprise_architect_linux.html).

