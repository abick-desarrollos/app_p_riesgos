-- ============================================================
-- Migration: Agregar columna titulo a no_conformidades
-- Fecha: 2026-09-16
-- ============================================================

-- Agregar la columna titulo (permite NULL para no romper registros existentes)
ALTER TABLE no_conformidades
  ADD COLUMN titulo VARCHAR(150) NULL AFTER numero;

-- Para registros existentes sin título, usar temporalmente "Sin título"
UPDATE no_conformidades
  SET titulo = 'Sin título'
  WHERE titulo IS NULL;

-- Hacer la columna NOT NULL después de la migración de datos
ALTER TABLE no_conformidades
  MODIFY COLUMN titulo VARCHAR(150) NOT NULL DEFAULT 'Sin título';
