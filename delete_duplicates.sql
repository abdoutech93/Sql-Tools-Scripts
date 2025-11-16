-- ========================================
-- Procédure stockée MySQL pour supprimer les doublons par lots
-- Évite les timeouts sur les grandes tables (1M+ lignes)
-- ========================================

DELIMITER $$

DROP PROCEDURE IF EXISTS remove_duplicates_batch$$

CREATE PROCEDURE remove_duplicates_batch(
    IN p_table_name VARCHAR(255),          -- Nom de la table
    IN p_unique_columns VARCHAR(500),      -- Colonnes pour définir l'unicité (ex: 'email,username')
    IN p_batch_size INT,                   -- Taille du lot (ex: 1000)
    IN p_primary_key VARCHAR(64)           -- Nom de la clé primaire (ex: 'id')
)
BEGIN
    DECLARE v_deleted_count INT DEFAULT 0;
    DECLARE v_total_deleted INT DEFAULT 0;
    DECLARE v_batch_number INT DEFAULT 1;
    DECLARE v_has_more BOOLEAN DEFAULT TRUE;
    DECLARE v_sql TEXT;
    
    -- Message de début
    SELECT CONCAT('=== Début de la suppression des doublons ===') AS status;
    SELECT CONCAT('Table: ', p_table_name) AS info;
    SELECT CONCAT('Colonnes uniques: ', p_unique_columns) AS info;
    SELECT CONCAT('Taille du lot: ', p_batch_size) AS info;
    
    -- Boucle de traitement par lots
    WHILE v_has_more DO
        -- Créer une table temporaire avec les IDs à supprimer pour ce lot
        DROP TEMPORARY TABLE IF EXISTS temp_ids_to_delete;
        
        -- Construire la clause ON dynamiquement
        SET @join_conditions = '';
        SET @remaining_cols = TRIM(p_unique_columns);
        SET @col_name = '';
        
        -- Boucle pour chaque colonne
        WHILE LENGTH(@remaining_cols) > 0 DO
            -- Extraire la prochaine colonne
            IF LOCATE(',', @remaining_cols) > 0 THEN
                SET @col_name = TRIM(SUBSTRING_INDEX(@remaining_cols, ',', 1));
                SET @remaining_cols = TRIM(SUBSTRING(@remaining_cols, LOCATE(',', @remaining_cols) + 1));
            ELSE
                SET @col_name = TRIM(@remaining_cols);
                SET @remaining_cols = '';
            END IF;
            
            -- Ajouter la condition de jointure
            IF LENGTH(@join_conditions) > 0 THEN
                SET @join_conditions = CONCAT(@join_conditions, ' AND ');
            END IF;
            SET @join_conditions = CONCAT(@join_conditions, 't1.', @col_name, ' = t2.', @col_name);
        END WHILE;
        
        SET @sql_find = CONCAT(
            'CREATE TEMPORARY TABLE temp_ids_to_delete AS ',
            'SELECT t1.', p_primary_key, ' as id_to_delete ',
            'FROM ', p_table_name, ' t1 ',
            'INNER JOIN ( ',
                'SELECT ', p_unique_columns, ', MIN(', p_primary_key, ') as keep_id ',
                'FROM ', p_table_name, ' ',
                'GROUP BY ', p_unique_columns, ' ',
                'HAVING COUNT(*) > 1 ',
                'LIMIT ', p_batch_size,
            ') t2 ON ', @join_conditions,
            ' WHERE t1.', p_primary_key, ' > t2.keep_id'
        );
        
        -- Exécuter la requête de recherche
        PREPARE stmt FROM @sql_find;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
        
        -- Compter combien d'IDs à supprimer dans ce lot
        SELECT COUNT(*) INTO v_deleted_count FROM temp_ids_to_delete;
        
        -- Si aucun ID trouvé, arrêter la boucle
        IF v_deleted_count = 0 THEN
            SET v_has_more = FALSE;
            SELECT 'Aucun doublon restant à traiter' AS status;
        ELSE
            -- Supprimer les doublons de ce lot
            SET @sql_delete = CONCAT(
                'DELETE FROM ', p_table_name, ' ',
                'WHERE ', p_primary_key, ' IN (SELECT id_to_delete FROM temp_ids_to_delete)'
            );
            
            PREPARE stmt FROM @sql_delete;
            EXECUTE stmt;
            DEALLOCATE PREPARE stmt;
            
            SET v_total_deleted = v_total_deleted + v_deleted_count;
            
            -- Afficher le progrès
            SELECT CONCAT('Lot #', v_batch_number, ' : ', v_deleted_count, ' lignes supprimées') AS progress;
            SELECT CONCAT('Total supprimé: ', v_total_deleted) AS total;
            
            SET v_batch_number = v_batch_number + 1;
            
            -- Petit délai pour ne pas surcharger le serveur (optionnel)
            DO SLEEP(0.1);
        END IF;
        
        -- Nettoyer la table temporaire
        DROP TEMPORARY TABLE IF EXISTS temp_ids_to_delete;
        
    END WHILE;
    
    -- Message final
    SELECT CONCAT('=== Terminé! Total de doublons supprimés: ', v_total_deleted, ' ===') AS result;
    
END$$

DELIMITER ;

-- ========================================
-- EXEMPLES D'UTILISATION
-- ========================================

-- Exemple 1: Supprimer les doublons basés sur la colonne 'email'
-- CALL remove_duplicates_batch('users', 'email', 1000, 'id');

-- Exemple 2: Supprimer les doublons basés sur 'user_id' et 'product_id'
-- CALL remove_duplicates_batch('orders', 'user_id,product_id', 1000, 'id');

-- Exemple 3: Supprimer les doublons basés sur plusieurs colonnes
-- CALL remove_duplicates_batch('transactions', 'customer_id,transaction_date,amount', 500, 'transaction_id');

-- ========================================
-- VÉRIFICATION DES DOUBLONS AVANT SUPPRESSION
-- ========================================

-- Pour compter les doublons avant de les supprimer:
/*
SELECT COUNT(*) - COUNT(DISTINCT email) as duplicates_count
FROM users;

-- Pour voir les doublons:
SELECT email, COUNT(*) as count
FROM users
GROUP BY email
HAVING count > 1;
*/
