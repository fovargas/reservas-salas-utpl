from datetime import time

from app.utils.validadores import sala_valida, horario_valido, se_solapan


def test_sala_valida_acepta_sala_del_catalogo():
    assert sala_valida("aula_magna") is True


def test_sala_valida_rechaza_sala_fuera_del_catalogo():
    assert sala_valida("cancha_futbol_inexistente") is False


def test_horario_valido_acepta_fin_posterior_a_inicio():
    assert horario_valido(time(8, 0), time(9, 0)) is True


def test_horario_valido_rechaza_fin_igual_a_inicio():
    assert horario_valido(time(8, 0), time(8, 0)) is False


def test_horario_valido_rechaza_fin_anterior_a_inicio():
    assert horario_valido(time(9, 0), time(8, 0)) is False


def test_se_solapan_detecta_interseccion():
    assert se_solapan(time(9, 0), time(11, 0), time(8, 0), time(10, 0)) is True


def test_se_solapan_no_detecta_horarios_contiguos():
    assert se_solapan(time(10, 0), time(11, 0), time(8, 0), time(10, 0)) is False


def test_se_solapan_no_detecta_horarios_separados():
    assert se_solapan(time(12, 0), time(13, 0), time(8, 0), time(10, 0)) is False
