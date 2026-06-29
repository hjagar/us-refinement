## US5: Zona Oculta para Contexto de IA en Markdown

**As a** desarrollador / colaborador del proyecto
**I want** que la salida del refinamiento incluya un bloque de comentarios HTML oculto en inglés con la traducción estructurada de la historia (en formato YAML)
**So that** los humanos puedan leer la historia en español de forma limpia en la UI, mientras que cualquier IA obtiene un payload estructurado en inglés, token-eficiente y listo para ser consumido por herramientas como `/sdd-new` o generadores de código.

### Acceptance criteria

**Scenario 1: Generación del bloque oculto en la salida**
- **Given** que finalicé el refinamiento de una historia de usuario en español
- **When** el skill genera el markdown de salida
- **Then** el archivo debe estructurar la información visible en español y agregar al final una sección encerrada entre `<!--` y `-->` que contenga un payload estructurado en formato YAML en inglés.

**Scenario 2: Persistencia y visualización en GitHub**
- **Given** que se publica la historia refinada en un issue de GitHub
- **When** un humano visualiza el issue en el navegador
- **Then** el bloque de comentarios de la IA no debe ser visible en la UI, pero debe permanecer en el markdown crudo accesible por la API (ej. al correr `gh issue view`).

**Scenario 3: Validación de metadatos en el YAML**
- **Given** el bloque oculto en inglés
- **When** se define el payload estructurado
- **Then** debe incluir obligatoriamente los campos `id`, `type` (con valores válidos como `feat`, `fix`, `refactor`, `docs`, `chore`), `breaking` (booleano) y `dependencies` (lista de IDs).

### Dependencies
- **US1: Soporte Multi-Agente (Portabilidad de Formatos)**

### Technical scope
- Backend: Sí (lógica de generación del bloque YAML en la salida del script del skill).
- Frontend: No.

### Assumptions / pending
- Se asume que el parser de markdown de los agentes del proyecto buscará y deserializará este bloque oculto usando delimitadores estándar.

<!-- [AI-DATA]
id: US5
type: feat
breaking: false
dependencies: [US1]
metadata:
  scope:
    backend: true
    frontend: false
  role: "developer"
  endpoint: "none"
  auth: "none"
  ui: "none"
scenarios:
  - name: "Generate hidden YAML block"
    given: "refined user story in Spanish is completed"
    when: "the refinement skill generates the output markdown"
    then: "it structures the visible content in Spanish and appends a technical YAML payload in English inside HTML comment tags"
  - name: "Persist and view on GitHub"
    given: "the refined user story is published as a GitHub issue"
    when: "a human views the issue in the browser UI"
    then: "the AI comment block remains invisible in the UI but persists in the raw markdown for API access"
  - name: "Validate YAML metadata fields"
    given: "the hidden English YAML block"
    when: "the structured payload is defined"
    then: "it must include id, type (feat, fix, refactor, docs, chore), breaking (boolean), and dependencies (list of IDs)"
-->
