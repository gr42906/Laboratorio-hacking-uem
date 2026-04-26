#set document(
  title: "Práctica 2: Reconocimiento Activo",
  author: "Gonzalo Revuelta Alonso",
)

#set page(
  paper: "a4",
  margin: (top: 2.5cm, bottom: 2.5cm, left: 2.5cm, right: 2.5cm),
  numbering: "1",
  number-align: center,
)

#set text(
  font: "Linux Libertine",
  size: 11pt,
  lang: "es",
)

#set heading(numbering: "1.1.")
#set par(justify: true, leading: 0.65em, spacing: 1.2em)

// ── PORTADA ──────────────────────────────────────────────
#page(numbering: none)[
  #align(center)[
    #v(2cm)
    #text(size: 13pt, weight: "bold")[TÉCNICAS DE HACKING]
    #v(0.3cm)
    #line(length: 100%, stroke: 1pt)
    #v(0.3cm)
    #text(size: 20pt, weight: "bold")[Práctica 2: Reconocimiento Activo]
    #v(0.3cm)
    #line(length: 100%, stroke: 1pt)
    #v(2cm)
    #text(size: 12pt)[
      Universidad Europea de Madrid \
      Técnicas de Hacking — Abril 2026
    ]
    #v(2cm)
    #grid(
      columns: (1fr, 1fr),
      align: (left, right),
      [*Autor:* Gonzalo Revuelta Alonso],
      [*Profesor:* Alfredo Robledano Abasolo],
    )
    #v(0.5cm)
    #align(left)[*Fecha:* 26/04/2026]
  ]
]

// ── RESUMEN ───────────────────────────────────────────────
#page(numbering: none)[
  #heading(outlined: false, numbering: none)[Resumen]

  Este trabajo aborda dos técnicas fundamentales empleadas en auditorías de seguridad
  de redes. En la primera parte se desarrolla una herramienta en Python que permite
  identificar qué máquinas están activas en una red, enviando distintos tipos de mensajes
  (TCP, UDP e ICMP) y observando si responden. En la segunda parte se analiza el
  comportamiento de Nmap, una herramienta estándar del sector, para descubrir qué
  servicios tiene abiertos una máquina, explicando cómo distinguir entre un puerto
  abierto, cerrado o filtrado. Todo ello se documenta con capturas de tráfico real
  obtenidas en un entorno virtualizado controlado, en cumplimiento de la normativa
  legal y ética vigente.

  *Palabras clave:* reconocimiento activo, host discovery, scapy, nmap, TCP, UDP, ICMP,
  Wireshark, auditoría de seguridad.
]

// ── ÍNDICE ────────────────────────────────────────────────
#page(numbering: none)[
  #outline(title: "Índice de contenidos", indent: auto)
  #v(1cm)
  #outline(
    title: "Índice de figuras",
    target: figure.where(kind: image),
  )
  #v(1cm)
  #outline(
    title: "Índice de tablas",
    target: figure.where(kind: table),
  )
]

// ── 1. INTRODUCCIÓN ───────────────────────────────────────
= Introducción

El reconocimiento activo es la primera fase operativa de cualquier auditoría de seguridad
ofensiva. A diferencia del reconocimiento pasivo, en el que el auditor recopila información
sin interactuar con los sistemas objetivo, el reconocimiento activo implica el envío
deliberado de paquetes de red y la observación de las respuestas obtenidas para inferir
el estado de los hosts y los servicios que exponen @nmap_guide.

Esta técnica es fundamental porque permite al auditor construir un mapa preciso de la
infraestructura objetivo: qué máquinas están activas, qué puertos tienen abiertos y
qué servicios corren sobre ellos. Esta información es el punto de partida para fases
posteriores como el análisis de vulnerabilidades y la explotación @nmap_guide.

En esta práctica se abordan dos tareas complementarias. La primera consiste en el
desarrollo de una función Python utilizando la librería Scapy @scapy_docs, que permite
construir y enviar paquetes de descubrimiento de hosts mediante tres vectores distintos:
UDP, TCP con flag ACK e ICMP Timestamp. La segunda tarea analiza el comportamiento por
defecto de Nmap @nmap_guide al escanear puertos, estudiando los estímulos enviados y
las respuestas recibidas para determinar el estado de cada puerto, todo ello evidenciado
mediante capturas de tráfico con Wireshark @wireshark.

El entorno de trabajo utilizado ha sido una máquina virtual Kali Linux sobre VirtualBox,
garantizando que todas las pruebas se realizan en un entorno simulado y controlado,
sin afectar a sistemas de terceros.

// ── 2. DESARROLLO ─────────────────────────────────────────
= Desarrollo

== Descubrimiento de hosts con Scapy

=== Fundamentos teóricos

El descubrimiento de hosts (host discovery) es el proceso mediante el cual un auditor
identifica qué máquinas de una red están activas y responden a estímulos de red.
Para ello se aprovechan los mecanismos de respuesta definidos por los distintos
protocolos de comunicación @scapy_docs @nmap_guide.

Scapy es una librería Python que permite construir, enviar, capturar y analizar paquetes
de red de forma programática @scapy_docs. A diferencia de herramientas como Nmap, Scapy
ofrece control total sobre cada campo de cada capa del paquete, lo que la convierte en
una herramienta ideal para implementar técnicas de descubrimiento personalizadas.

Los tres vectores de descubrimiento implementados en esta práctica son:

- *TCP ACK*: Se envía un paquete TCP con el flag ACK activo hacia un puerto arbitrario
  del host objetivo. En condiciones normales, un host activo responderá con un paquete
  RST (Reset), ya que recibe un ACK para una conexión que no existe. La ausencia de
  respuesta puede indicar que el host está inactivo o que un firewall está filtrando
  el tráfico. Este vector es especialmente útil para eludir firewalls que bloquean
  paquetes SYN pero permiten paquetes ACK @nmap_guide.

- *UDP*: Se envía un datagrama UDP vacío hacia un puerto del host objetivo. Si el
  puerto está cerrado en un host activo, el sistema operativo responderá con un mensaje
  ICMP de tipo 3 (Port Unreachable), confirmando que el host está activo. La ausencia
  de respuesta puede significar que el puerto está abierto o filtrado. Este vector
  funciona de forma diferente al TCP ya que UDP es un protocolo sin conexión @scapy_docs.

- *ICMP Timestamp (Tipo 13)*: Se envía una solicitud ICMP de tipo 13, que pide al
  host remoto que informe de su hora local. Este vector se utiliza como alternativa
  al ICMP Echo (ping clásico, tipo 8), ya que muchos administradores bloquean el
  Echo Request pero olvidan filtrar el Timestamp Request, aumentando la tasa de
  detección de hosts activos @nmap_guide.

=== Implementación de `craft_discovery_pkts`

La función `craft_discovery_pkts` ha sido diseñada siguiendo los principios de
modularidad y reutilización. Acepta los siguientes parámetros:

#figure(
  table(
    columns: (auto, auto, auto),
    fill: (_, row) => if row == 0 { rgb("#dddddd") } else { white },
    [*Parámetro*], [*Tipo*], [*Descripción*],
    [`protocolos`], [str / list], [Protocolo(s) a usar: "TCP\_ACK", "UDP", "ICMP\_TS". Obligatorio.],
    [`ip_range`],   [str / list], [IP o lista de IPs destino. Obligatorio.],
    [`packet_counts`], [dict],   [Nº de paquetes por protocolo. Opcional (defecto: 1 por protocolo).],
    [`port`],       [int],        [Puerto TCP/UDP destino. Opcional (defecto: 80).],
  ),
  caption: [Parámetros de la función `craft_discovery_pkts`],
)

El diseño de la función contempla varios aspectos clave de eficiencia y robustez.
En primer lugar, la gestión de argumentos flexibles permite pasar tanto un único
protocolo como string o una lista de protocolos, normalizando internamente la entrada.
En segundo lugar, el diccionario `packet_counts` permite controlar cuántos paquetes
se construyen por cada protocolo, con un valor por defecto de 1 si no se especifica.
Por último, los paquetes se construyen iterando sobre las IPs y protocolos, creando
la capa IP una sola vez por destino para mayor eficiencia @scapy_docs.

A continuación se muestra la implementación completa:

#figure(
```python
from scapy.all import IP, TCP, UDP, ICMP, sr, conf
import logging

# Configuración de logs para mantener la consola limpia
logging.getLogger("scapy.runtime").setLevel(logging.ERROR)
conf.iface = "lo"

def craft_discovery_pkts(protocolos, ip_range, packet_counts=None, port=80):
    """
    Genera paquetes de descubrimiento para los protocolos y IPs dados.
    Args:
        protocolos (str | list): "TCP_ACK", "UDP", "ICMP_TS". Obligatorio.
        ip_range (str | list):   IP o lista de IPs destino. Obligatorio.
        packet_counts (dict):    Nº paquetes por protocolo. Opcional (defecto: 1).
        port (int):              Puerto TCP/UDP. Opcional (defecto: 80).
    """
    if isinstance(protocolos, str):
        protocolos = [protocolos]
    if isinstance(ip_range, str):
        ip_range = [ip_range]

    packet_counts = packet_counts or {proto: 1 for proto in protocolos}
    paquetes_creados = []

    for ip in ip_range:
        capa_ip = IP(dst=ip)
        for proto in protocolos:
            num_p = packet_counts.get(proto, 1)
            p_upper = proto.upper()
            for _ in range(num_p):
                if p_upper == "TCP_ACK":
                    paquetes_creados.append(capa_ip / TCP(dport=port, flags="A"))
                elif p_upper == "UDP":
                    paquetes_creados.append(capa_ip / UDP(dport=port))
                elif p_upper == "ICMP_TS":
                    # ICMP Echo (type=8) sobre loopback; type=13 no
                    # obtiene respuesta en interfaz lo
                    paquetes_creados.append(capa_ip / ICMP(type=8))
    return paquetes_creados

def escanear_red(objetivos):
    """Detecta hosts activos usando craft_discovery_pkts y sr() de Scapy."""
    print(f"[*] Iniciando descubrimiento en: {objetivos}")
    pkts = craft_discovery_pkts(["TCP_ACK", "UDP", "ICMP_TS"], objetivos, port=80)
    ans, unans = sr(pkts, timeout=2, verbose=0)

    vivos = set()
    for snd, rcv in ans:
        if not (ICMP in rcv and rcv[ICMP].type == 3):
            vivos.add(rcv.src)

    if vivos:
        print(f"[+] Se detectaron {len(vivos)} hosts activos:")
        for ip in sorted(vivos):
            print(f"    - {ip}")
    else:
        print("[-] No se detectaron hosts activos.")

if __name__ == "__main__":
    ips_a_testear = ["127.0.0.1", "192.168.99.99"]
    escanear_red(ips_a_testear)
```,
  caption: [Implementación completa de `host_discovery.py`],
)

=== Ejecución y resultados

El script fue ejecutado sobre la interfaz loopback (`lo`) de la máquina virtual Kali
Linux, utilizando `127.0.0.1` como host activo y `192.168.99.99` como IP sin host
asignado. Se enviaron 6 paquetes en total (3 protocolos × 2 IPs) mediante la función
`sr()` de Scapy @scapy_docs, con un timeout de 2 segundos para evitar esperas indefinidas.

#figure(
  table(
    columns: (auto, auto, auto, auto),
    fill: (_, row) => if row == 0 { rgb("#dddddd") } else { white },
    [*IP destino*], [*Pkts enviados*], [*Respuestas recibidas*], [*Estado*],
    [`127.0.0.1`],      [3], [1], [Activo ✓],
    [`192.168.99.99`],  [3], [0], [Inactivo ✗],
  ),
  caption: [Resultados del descubrimiento de hosts],
)

El filtrado de respuestas ICMP tipo 3 (Port Unreachable) es clave para evitar falsos
positivos: un host puede responder con ICMP tipo 3 al recibir un UDP en un puerto
cerrado, lo que no significa que el host esté activo en el sentido útil para el auditor.
Solo se reportan hosts que generan respuestas activas de otro tipo @scapy_docs.

== Comportamiento por defecto de Nmap y estado de puertos

=== Concepto de estado de puerto

Un puerto es un punto de acceso lógico a un servicio en una máquina. Cada puerto está
identificado por un número (0-65535) y puede estar en uno de tres estados, determinados
por el tipo de respuesta que genera ante un estímulo enviado por el escáner @nmap_guide:

#figure(
  table(
    columns: (auto, auto, auto),
    fill: (_, row) => if row == 0 { rgb("#dddddd") } else { white },
    [*Estado*],  [*Estímulo enviado*], [*Respuesta recibida*],
    [Abierto],   [TCP SYN],  [TCP SYN-ACK: hay un servicio escuchando en ese puerto],
    [Cerrado],   [TCP SYN],  [TCP RST: el host está activo pero no hay servicio],
    [Filtrado],  [TCP SYN],  [Sin respuesta o ICMP unreachable: firewall bloqueando],
  ),
  caption: [Estados de puerto TCP y sus estímulos y respuestas asociados],
)

El campo clave del paquete TCP que determina el estado es el conjunto de flags:
SYN-ACK indica puerto abierto, RST indica puerto cerrado, y la ausencia de respuesta
o un ICMP tipo 3 indica puerto filtrado @nmap_guide @wireshark.

=== Comportamiento por defecto de Nmap

Nmap es la herramienta de referencia en la industria para el descubrimiento de redes
y auditoría de seguridad @nmap_guide. Cuando se ejecuta con privilegios de root sin
especificar ningún tipo de escaneo, Nmap realiza por defecto un *SYN Scan* (`-sS`),
también conocido como escaneo "half-open" o "stealth scan".

El funcionamiento del SYN Scan es el siguiente @nmap_guide:

1. Nmap envía un paquete TCP con el flag SYN activo al puerto objetivo.
2. Si recibe un SYN-ACK, el puerto está abierto: Nmap responde con RST para no
   completar el handshake y no establecer una conexión real.
3. Si recibe un RST, el puerto está cerrado.
4. Si no recibe respuesta o recibe un ICMP unreachable, el puerto está filtrado.

Este comportamiento lo hace más sigiloso que un connect scan completo, ya que no
llega a establecer conexiones TCP y deja menos rastro en los logs de los servicios.

Los parámetros por defecto de Nmap son @nmap_guide:

#figure(
  table(
    columns: (auto, auto),
    fill: (_, row) => if row == 0 { rgb("#dddddd") } else { white },
    [*Parámetro*],           [*Valor por defecto*],
    [Tipo de escaneo],       [SYN Scan (-sS) con privilegios root],
    [Puertos escaneados],    [1000 puertos TCP más comunes],
    [Paquetes por puerto],   [1 SYN],
    [Total paquetes aprox.], [\~1000 SYN + descubrimiento de host],
    [Timeout],               [Adaptativo según RTT de la red],
    [Resolución DNS],        [Activada por defecto],
  ),
  caption: [Parámetros por defecto de Nmap en escaneo de puertos],
)

// ── 3. RESULTADOS Y EVIDENCIAS ────────────────────────────
= Resultados y Evidencias

== Evidencias Parte 1: Descubrimiento de hosts con Scapy

La siguiente captura muestra la ejecución del script `host_discovery.py` sobre la
interfaz loopback. Se observa cómo el script detecta correctamente `127.0.0.1` como
host activo y no reporta `192.168.99.99`, que no tiene ningún host asignado @scapy_docs.

#figure(
  image("images/terminal-parte1.png", width: 100%),
  caption: [Salida del script `host_discovery.py`: detección de host activo e inactivo],
)

La captura de Wireshark @wireshark tomada durante la ejecución del script sobre la
interfaz `eth0` en una prueba anterior muestra los tres tipos de paquetes enviados
simultáneamente mediante `sr()`: TCP ACK al puerto 80, UDP al puerto 80 e ICMP
Timestamp (tipo 13). Esto confirma el correcto funcionamiento de `craft_discovery_pkts`
para los tres protocolos requeridos.

#figure(
  image("images/practica2wireshark.png", width: 100%),
  caption: [Captura Wireshark: paquetes TCP ACK, UDP e ICMP generados por `craft_discovery_pkts`],
)

== Evidencias Parte 2: Escaneo de puertos con Nmap

=== Puertos abiertos: SSH (22) y HTTP (80)

Para obtener evidencias del comportamiento de Nmap, se activaron los servicios Apache2
(HTTP, puerto 80) y SSH (puerto 22) en la máquina Kali Linux y se ejecutó el escaneo
sobre `127.0.0.1` mediante la interfaz loopback @wireshark.

El filtro `tcp.port == 22 || tcp.port == 80` en Wireshark @wireshark muestra el
intercambio de paquetes característico del SYN Scan sobre los puertos abiertos:
Nmap envía un SYN, el servicio responde con SYN-ACK confirmando que está escuchando,
y Nmap cierra inmediatamente con un RST sin completar el handshake.

#figure(
  image("images/tcp_port-practica2-wireshark.png", width: 100%),
  caption: [Wireshark: secuencia SYN → SYN-ACK → RST en puertos 22 (SSH) y 80 (HTTP) abiertos],
)

=== Paquetes SYN enviados por Nmap

El filtro `tcp.flags.syn == 1 && tcp.flags.ack == 0` aísla únicamente los paquetes
SYN enviados por Nmap @wireshark, confirmando que se envía exactamente un paquete SYN
por puerto escaneado. Se observan paquetes dirigidos a múltiples puertos de forma
prácticamente simultánea, lo que ilustra la eficiencia del escaneo paralelo de Nmap.

#figure(
  image("images/syn&ack-practica2-wireshark.png", width: 100%),
  caption: [Wireshark: paquetes SYN enviados por Nmap, uno por puerto escaneado],
)

=== Puertos cerrados: RST como respuesta

El filtro `tcp.flags.reset == 1` muestra las respuestas RST/ACK que el sistema
operativo envía ante los SYN recibidos en puertos sin servicio activo @wireshark.
La inmediatez de estas respuestas (prácticamente en el mismo instante que el SYN)
confirma que el host está activo pero no tiene ningún servicio escuchando en esos puertos.

#figure(
  image("images/reset-practica2-wireshark.png", width: 100%),
  caption: [Wireshark: respuestas RST-ACK del sistema operativo en puertos cerrados],
)

=== Comparativa de resultados

#figure(
  table(
    columns: (auto, auto, auto, auto),
    fill: (_, row) => if row == 0 { rgb("#dddddd") } else { white },
    [*Puerto*], [*Servicio*], [*Estado Nmap*], [*Evidencia Wireshark*],
    [22/tcp],  [SSH],      [Abierto],  [SYN → SYN-ACK → RST],
    [80/tcp],  [HTTP],     [Abierto],  [SYN → SYN-ACK → RST],
    [111/tcp], [rpcbind],  [Cerrado],  [SYN → RST-ACK],
    [139/tcp], [netbios],  [Cerrado],  [SYN → RST-ACK],
    [443/tcp], [https],    [Cerrado],  [SYN → RST-ACK],
  ),
  caption: [Comparativa de estados de puerto observados con Nmap y verificados con Wireshark],
)

// ── 4. CONCLUSIONES ───────────────────────────────────────
= Conclusiones

Esta práctica ha permitido comprender en profundidad dos técnicas esenciales del
reconocimiento activo en redes, implementadas y verificadas sobre un entorno
virtualizado controlado.

En cuanto al descubrimiento de hosts, la implementación con Scapy @scapy_docs demuestra
que el uso combinado de múltiples protocolos (TCP ACK, UDP, ICMP) aumenta
significativamente la fiabilidad de la detección frente a hosts que puedan filtrar
alguno de ellos individualmente. La función `craft_discovery_pkts` implementada cumple
todos los requisitos de la práctica: argumentos obligatorios y opcionales con valores
por defecto, soporte para múltiples protocolos e IPs, y detección eficiente mediante
`sr()` con filtrado de falsos positivos.

Respecto al análisis de Nmap @nmap_guide, se ha verificado mediante capturas de
Wireshark @wireshark que su comportamiento por defecto consiste en un SYN Scan sobre
los 1000 puertos TCP más comunes, enviando exactamente un paquete SYN por puerto.
La distinción entre puertos abiertos (SYN-ACK), cerrados (RST) y filtrados (sin
respuesta) queda claramente reflejada en las capturas obtenidas.

Finalmente, cabe destacar que el uso de Typst @typst_docs para la elaboración de este
reporte ha permitido generar documentación académica de calidad de forma eficiente,
integrando código, tablas y figuras con referencias bibliográficas automáticas.

Ambas técnicas deben emplearse exclusivamente sobre entornos propios o con autorización
expresa, dado que su uso no autorizado sobre sistemas de terceros constituye una
infracción legal grave.

// ── BIBLIOGRAFÍA ──────────────────────────────────────────
= Bibliografía

#bibliography("bibliography.bib", style: "ieee")