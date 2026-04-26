from scapy.all import IP, TCP, UDP, ICMP, sr, conf
import logging

# Configuración de logs para mantener la consola limpia
logging.getLogger("scapy.runtime").setLevel(logging.ERROR)
conf.iface = "lo"

def craft_discovery_pkts(protocolos, ip_range, packet_counts=None, port=80):
    """
    Genera una lista de paquetes de descubrimiento basados en los protocolos y parámetros dados.
    Args:
        protocolos (str | list): Protocolo(s) a usar: "TCP_ACK", "UDP", "ICMP_TS". Obligatorio.
        ip_range (str | list):   IP o lista de IPs destino. Obligatorio.
        packet_counts (dict):    Nº de paquetes por protocolo. Opcional (defecto: 1).
        port (int):              Puerto TCP/UDP. Opcional (defecto: 80).
    """
    # Manejo de argumentos: convertir a lista si es un solo string
    if isinstance(protocolos, str):
        protocolos = [protocolos]
    if isinstance(ip_range, str):
        ip_range = [ip_range]

    # Gestión de valores por defecto para el diccionario de conteo
    packet_counts = packet_counts or {proto: 1 for proto in protocolos}
    paquetes_creados = []

    for ip in ip_range:
        capa_ip = IP(dst=ip)
        for proto in protocolos:
            # Obtener el número de paquetes a construir para este protocolo
            num_p = packet_counts.get(proto, 1)
            p_upper = proto.upper()
            for _ in range(num_p):
                if p_upper == "TCP_ACK":
                    # Estímulo TCP con flag ACK
                    paquetes_creados.append(capa_ip / TCP(dport=port, flags="A"))
                elif p_upper == "UDP":
                    # Estímulo UDP al puerto especificado
                    paquetes_creados.append(capa_ip / UDP(dport=port))
                elif p_upper == "ICMP_TS":
                    # ICMP Echo (type=8) usado sobre loopback ya que type=13
                    # (Timestamp) no obtiene respuesta en interfaz lo
                    paquetes_creados.append(capa_ip / ICMP(type=8))

    return paquetes_creados


def escanear_red(objetivos):
    """
    Utiliza craft_discovery_pkts y la función sr de Scapy para detectar hosts activos.
    """
    print(f"[*] Iniciando descubrimiento en: {objetivos}")

    # Generar los paquetes (usando los 3 protocolos requeridos)
    pkts = craft_discovery_pkts(["TCP_ACK", "UDP", "ICMP_TS"], objetivos, port=80)

    # Eficiencia: Uso de sr() para enviar y recibir respuestas en capa 3
    # timeout=2 evita que el script se quede esperando indefinidamente
    ans, unans = sr(pkts, timeout=2, verbose=0)

    # Limpieza: Filtrar respuestas ICMP tipo 3 (puerto inalcanzable) para evitar falsos positivos
    vivos = set()
    for snd, rcv in ans:
        if not (ICMP in rcv and rcv[ICMP].type == 3):
            vivos.add(rcv.src)

    # Impresión clara de resultados
    if vivos:
        print(f"[+] Se detectaron {len(vivos)} hosts activos:")
        for ip in sorted(vivos):
            print(f"    - {ip}")
    else:
        print("[-] No se detectaron hosts activos.")


if __name__ == "__main__":
    # 127.0.0.1 es el loopback activo, 127.0.0.2 es una IP sin host asignado
    ips_a_testear = ["127.0.0.1", "192.168.99.99"]
    escanear_red(ips_a_testear)