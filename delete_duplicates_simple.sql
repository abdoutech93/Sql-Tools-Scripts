-- ========================================
-- VERSION SIMPLIFIÉE - Procédure MySQL pour supprimer les doublons
-- Plus simple à comprendre et à utiliser
-- ========================================

DELIMITER $$

DROP PROCEDURE IF EXISTS clean_duplicates$$

CREATE PROCEDURE clean_duplicates(
    IN table_name VARCHAR(255),
    IN unique_column VARCHAR(255),
    IN batch_size INT
)
BEGIN
    DECLARE deleted INT DEFAULT 0;
    DECLARE total INT DEFAULT 0;
    DECLARE batch INT DEFAULT 1;
    
    SELECT CONCAT('Nettoyage de la table: ', table_name) AS info;
    
    -- Boucle de suppression par lots
    cleanup_loop: LOOP
        -- Supprimer un lot de doublons (garde le MIN id)
        SET @query = CONCAT(
            'DELETE t1 FROM ', table_name, ' t1 ',
            'INNER JOIN ', table_name, ' t2 ',
            'ON t1.', unique_column, ' = t2.', unique_column, ' ',
            'AND t1.id > t2.id ',
            'LIMIT ', batch_size
        );
        
        PREPARE stmt FROM @query;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
        
        SET deleted = ROW_COUNT();
        SET total = total + deleted;
        
        -- Si aucune suppression, on a terminé
        IF deleted = 0 THEN
            LEAVE cleanup_loop;
        END IF;
        
        SELECT CONCAT('Lot ', batch, ': ', deleted, ' supprimés | Total: ', total) AS progress;
        SET batch = batch + 1;
        
        -- Pause courte
        DO SLEEP(0.1);
    END LOOP;
    
    SELECT CONCAT('✓ Terminé! ', total, ' doublons supprimés') AS result;
END$$

DELIMITER ;

-- ========================================
-- EXEMPLES D'UTILISATION
-- ========================================

-- Supprimer les doublons d'email par lots de 1000
-- CALL clean_duplicates('users', 'email', 1000);

-- Supprimer les doublons de username par lots de 500
-- CALL clean_duplicates('members', 'username', 500);

-- ========================================
-- VÉRIFIER LES DOUBLONS
-- ========================================

-- Compter les doublons:
-- SELECT COUNT(*) - COUNT(DISTINCT email) FROM users;

-- Voir les doublons:
-- SELECT email, COUNT(*) as nb FROM users GROUP BY email HAVING nb > 1;
