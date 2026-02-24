# 📱 ISTEC Check-in

Aplicação mobile desenvolvida em Flutter para realização de check-in em eventos do campus ISTEC, utilizando leitura de QR Code e validação por geolocalização.


## 🎯 Objetivo

O objetivo da aplicação é permitir que um aluno realize check-in em um evento presencial através de:
	•	📷 Leitura de QR Code
	•	📍 Validação por geolocalização (raio permitido)
	•	💾 Armazenamento local do histórico de presenças


## 🚀 Funcionalidades

- ✅ Login (simulado)
- ✅ Dashboard com última atividade
- ✅ Leitura de QR Code (Mobile Scanner)
- ✅ Solicitação de permissão de câmera
- ✅ Solicitação de permissão de localização
- ✅ Validação de distância até o local do evento
- ✅ Histórico de presenças persistido localmente
- ✅ Formatação de data e hora no padrão HH:MM DD/MM/AAAA



## 🧠 Como funciona

1. O utilizador realiza login.
2. Ao clicar em **REALIZAR CHECK-IN**, a câmera é ativada.
3. O QR Code é lido.
4. O sistema:
   - Valida se o QR corresponde ao evento esperado  
   - Obtém a localização atual do utilizador  
   - Calcula a distância até o ponto configurado  
   - Verifica se está dentro do raio permitido  
5. Se válido, o check-in é registrado no histórico.


## 📍 Validação de Localização

A validação é feita comparando:

- Latitude e Longitude do utilizador  
- Latitude e Longitude do evento (definidas no `geo_helper.dart`)  
- Raio máximo permitido (em metros)  

Caso o utilizador esteja fora do raio, o check-in é bloqueado.


## 🛠️ Tecnologias Utilizadas

- Flutter  
- Dart  
- Provider (gerenciamento de estado)  
- Mobile Scanner (leitura de QR Code)  
- Geolocator (localização)  
- Shared Preferences (persistência local)  



## 📦 Estrutura do Projeto

lib/
 ├── models/
 |    └── check_in.dart
 ├── providers/
 |    └── app_state.dart
 ├── screens/
 │    ├── login_screen.dart
 │    ├── dashboard_screen.dart
 │    ├── history_screen.dart
 │    └── scanner_screen.dart
 ├── utils/
 │    ├── geo_helper.dart
 │    └── geo.ts
 └── main.dart




▶️ Como Executar
	1.	Clonar o repositório:

git clone https://github.com/SEU_USUARIO/istec_checkin.git

	2.	Acessar a pasta do projeto:

cd istec_checkin

	3.	Instalar dependências:

flutter pub get

	4.	Executar:

flutter run




🔐 Permissões Necessárias
	•	Câmera
	•	Localização (GPS)

As permissões são solicitadas automaticamente pelo aplicativo.



📌 QR Code de Teste

Para realizar o check-in, o QR Code deve conter:

SALA_ISTEC_2026




👩‍💻 Autora

Gabriella Rezende e Thales Hayashi
Curso: Desenvolvimento de Dispositivos Móveis
ISTEC
