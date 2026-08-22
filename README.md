# Enterprise Architect 14 no Linux para a UFSC

Instala o Enterprise Architect 14.1 no Linux com Wine e configura a licença acadêmica da UFSC.

Testado no Omarchy 4.0 com Wine 11.15. O programa abriu modelos `.eap` e obteve a licença `EA Academic` pela VPN da UFSC.

## Antes de instalar

Obtenha estes arquivos por um canal autorizado da UFSC e coloque-os na pasta do projeto:

```text
enterprise-architect-linux-ufsc/
├── install-linux.sh
├── KeyStore.reg
└── SetupFull.msi
```

O MSI e o arquivo de licença não estão neste repositório porque não devem ser publicados.

## Quem só precisa executar o script

Nestes sistemas, o script instala as dependências automaticamente:

- Omarchy e Arch Linux
- EndeavourOS, CachyOS e outros derivados do Arch
- Debian e Ubuntu
- Fedora

Execute como usuário normal, sem colocar `sudo` antes:

```bash
chmod +x install-linux.sh
./install-linux.sh
```

O gerenciador de pacotes pedirá sua senha quando necessário. A primeira instalação baixa aproximadamente 910 MB para preparar as bibliotecas XML exigidas pelo EA 14.

## Quem precisa instalar dependências antes

Em openSUSE e outras distribuições não listadas acima, instale manualmente:

- Wine com suporte a programas Windows de 32 bits
- Winetricks
- UnixODBC
- 7-Zip, com o comando `7z`

Confirme que estes comandos existem:

```bash
wine --version
wineserver --version
winetricks --version
7z --help
```

Depois execute `./install-linux.sh`. O script não aceita sistemas ARM, como Raspberry Pi e alguns Chromebooks.

## Conectar à licença da UFSC

Antes de abrir o EA, conecte-se à `redeUFSC` ou à VPN da UFSC. As instruções oficiais estão na [página do serviço de VPN](https://setic.ufsc.br/servicos/acesso-a-redeufsc/servico-de-vpn-virtual-private-network/).

Teste o acesso ao servidor de licenças:

```bash
getent hosts licenciador2012.setic.ufsc.br
```

O comando deve mostrar um endereço IP. Sem resultado, verifique a VPN.

## Abrir o programa

Use `Enterprise Architect 14` no menu de aplicativos ou execute:

```bash
enterprise-architect
```

Para abrir um modelo:

```bash
enterprise-architect /caminho/modelo.eap
```

Arquivos `.eap`, `.eapx` e `.feap` também ficam associados ao aplicativo.

## Problemas comuns

### "Error creating XML Parser"

Execute novamente o instalador atualizado:

```bash
./install-linux.sh
```

O script instala e registra as bibliotecas MSXML3 e MSXML4 necessárias.

### Licença indisponível

Confira a VPN com o comando `getent` mostrado acima. Se o servidor responder, mas não houver licença, o conjunto de licenças pode estar ocupado ou o serviço pode estar indisponível. Use o [atendimento da SeTIC](https://atendimento.setic.ufsc.br/).

### O programa não abre

Gere um log:

```bash
WINEDEBUG=err+all enterprise-architect 2>&1 | tee ea-wine-errors.log
```

Linhas com `fixme` são avisos internos do Wine. Procure linhas com `err:` perto do fim do arquivo.

## Onde a instalação fica

```text
~/.local/share/enterprise-architect-14/
~/.local/bin/enterprise-architect
~/.local/share/applications/enterprise-architect.desktop
```

Salve seus modelos em uma pasta normal, como `~/Documentos`, e mantenha cópias de segurança.

## Aviso

Enterprise Architect é um produto da Sparx Systems. Este projeto não distribui o programa nem concede licença de uso. O acesso depende de autorização e vínculo válido com a UFSC.

