# Enterprise Architect 14 no Linux para a UFSC

Instala o Enterprise Architect 14.1 no Linux com Wine e configura a licença acadêmica da UFSC.

Testado no Omarchy 4.0 com Wine 11.15.

## Instalação

O script baixa e instala as dependências automaticamente nestes sistemas:

- Arch Linux, Omarchy, EndeavourOS, CachyOS e derivados
- Fedora
- Ubuntu e Debian

Clone o repositório:

```bash
git clone https://github.com/GustavoDorow/enterprise-architect-linux-ufsc.git
cd enterprise-architect-linux-ufsc
```

Obtenha `SetupFull.msi` e `KeyStore.reg` por um canal autorizado da UFSC e coloque os dois arquivos dentro da pasta clonada:

```text
enterprise-architect-linux-ufsc/
├── install-linux.sh
├── KeyStore.reg
└── SetupFull.msi
```

Execute o instalador como seu usuário normal:

```bash
chmod +x install-linux.sh
./install-linux.sh
```

Não use `sudo ./install-linux.sh`. O próprio script pedirá sua senha quando o gerenciador de pacotes precisar dela.

Na primeira instalação, o Winetricks baixa aproximadamente 910 MB para preparar as bibliotecas XML exigidas pelo EA 14.

## Código de ativação

Quando o Enterprise Architect solicitar o código de ativação, use o código disponibilizado no Moodle:

```text
8BSX
```

## Outras distribuições

Em distribuições diferentes das listadas acima, instale antes:

- Wine com suporte a programas de 32 bits
- Winetricks
- UnixODBC
- 7-Zip, com o comando `7z`

Depois execute `./install-linux.sh` normalmente. Sistemas ARM não são suportados.

## VPN da UFSC

Conecte-se à `redeUFSC` ou à VPN antes de abrir o programa.

Configuração oficial: [Serviço de VPN da UFSC](https://setic.ufsc.br/servicos/acesso-a-redeufsc/servico-de-vpn-virtual-private-network/)

## Abrir o programa

Procure por `Enterprise Architect 14` no menu de aplicativos ou execute:

```bash
enterprise-architect
```

Para abrir um modelo:

```bash
enterprise-architect /caminho/modelo.eap
```

O instalador associa arquivos `.eap`, `.eapx` e `.feap` ao programa.

## Aviso

`SetupFull.msi` e `KeyStore.reg` não estão neste repositório e não devem ser publicados. Obtenha-os somente por meios autorizados pela UFSC.

Enterprise Architect é um produto da Sparx Systems. Este projeto não distribui o programa nem concede licença de uso.
