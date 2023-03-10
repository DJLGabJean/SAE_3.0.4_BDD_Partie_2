-- Suppression des tables et des constraintes associés

DROP TABLE IF EXISTS Salle CASCADE;
DROP TABLE IF EXISTS ELP CASCADE;
DROP TABLE IF EXISTS Groupes CASCADE;
DROP TABLE IF EXISTS Reservation CASCADE;

-- Suppression des procédures

DROP PROCEDURE IF EXISTS MajGroupe;
DROP PROCEDURE IF EXISTS ReservationsGroupe;

-- Suppression des fonctions

DROP FUNCTION IF EXISTS EstLibre;

-- Création des tables

CREATE TABLE Salle (NoSalle VARCHAR(3) PRIMARY KEY,
		    Categorie VARCHAR(10),
		    NbPlaces INT CHECK(NbPlaces>=0)
		    );

CREATE TABLE ELP (CodeELP VARCHAR(5) PRIMARY KEY,
		  NomELP VARCHAR(40) NOT NULL,
		  Formation VARCHAR(15) NOT NULL,
		  HC INT CHECK(HC>=0),
		  HTD INT CHECK(HC>=0),
		  HTP INT CHECK(HTP>=0),
		  HCRes INT,
		  HTDRes INT,
		  HTPRes INT
		  );

CREATE TABLE Groupes (Groupe VARCHAR(15) PRIMARY KEY,
		      Formation VARCHAR(15) NOT NULL REFERENCES ELP(Formation),
		      Effectif INT NOT NULL CHECK(Effectif>=0)
		      );

CREATE TABLE Reservation (NoReservation INT AUTO_INCREMENT PRIMARY KEY,
			  NoSalle VARCHAR(3) REFERENCES Salle(NoSalle),
			  CodeELP VARCHAR(5) REFERENCES ELP(CodeELP),
			  Groupe VARCHAR(15) REFERENCES Groupes(Groupe),
			  Formation VARCHAR(15) REFERENCES ELP(Formation),
			  Nature VARCHAR(15) NOT NULL,
			  Debut DATETIME,
			  Duree INT
			  );


-- Validation des données

COMMIT;

-- Création des procédures/fonctions 

DELIMITER //
CREATE PROCEDURE MajGroupe (Gpe VARCHAR(10), Forma VARCHAR(10), Eff DECIMAL (4,2)) 
BEGIN
     IF Gpe IS NULL OR Forma IS NULL OR Eff IS NULL THEN
        SELECT ("Tous les paramètres sont obligatoires");
    ELSE
        SELECT COUNT(*) INTO @count FROM Groupes WHERE Groupe = Gpe AND Formation = Forma;
        IF @count = 0 AND Eff > 0 THEN
            INSERT INTO Groupes(Groupe, Formation, Effectif) VALUES(Gpe, Forma, Eff);
        ELSEIF @count > 0 AND Eff > 0 THEN
            UPDATE Groupes SET Effectif = Eff WHERE Groupe = Gpe AND Formation = Forma;
		ELSEIF @count > 0 AND Eff < 0 THEN
			SELECT ("L'effectif est négatif");
        ELSE
            DELETE FROM Groupes WHERE Groupe = Gpe AND Formation = Forma;
            DELETE FROM Reservation WHERE Groupe = Gpe AND Formation = Forma;
        END IF;
    END IF;
END;
//

CREATE PROCEDURE ReservationsGroupe (Gpe VARCHAR(10), Forma VARCHAR(10))
BEGIN
    
	DECLARE Groupe_p INT;
	DECLARE Forma_p INT;
    DECLARE Liste_p INT;

	IF Gpe IS NULL THEN
		SELECT r.Debut, CONVERT(r.Debut + (CONVERT((CONCAT(r.Duree DIV 60, ':', r.Duree MOD 60)), TIME)),DATETIME) AS Fin, r.CodeELP, e.NomELP, r.Nature, r.NoSalle, r.Groupe
		FROM Reservation r
		JOIN ELP e ON r.CodeELP = e.CodeELP
		WHERE r.Formation = Forma
		GROUP BY r.NoReservation;
        
    ELSE
		SELECT COUNT(*) INTO Groupe_p FROM Groupes WHERE Groupe = Gpe;
        SELECT COUNT(*) INTO Forma_p FROM Groupes WHERE Formation = Forma;
		IF Groupe_p = 0 OR Forma_p = 0 THEN
			SELECT ("Groupe ou formation inexistant(e)");
		ELSE
			SELECT COUNT(*) INTO Liste_p
            FROM Reservation r
            JOIN ELP e ON r.CodeELP = e.CodeELP 
            WHERE r.Groupe = Gpe AND r.Formation = Forma;
            
            IF Liste_p = 0 THEN
				SELECT ("Pas de réservation pour ce groupe ou cette formation");
                
            ELSE
				SELECT r.Debut, CONVERT(r.Debut + (CONVERT((CONCAT(r.Duree DIV 60, ':', r.Duree MOD 60)), TIME)),DATETIME) AS Fin, r.CodeELP, e.NomELP, r.Nature, r.NoSalle, r.Groupe
				FROM Reservation r
				JOIN ELP e ON r.CodeELP = e.CodeELP
				WHERE r.Groupe = Gpe AND r.Formation = Forma
				GROUP BY r.NoReservation;
            
            END IF;
		END IF;
    END IF;
END;
//

CREATE FUNCTION EstLibre (Gpe VARCHAR(10), Forma VARCHAR(10), Debut DATETIME, Duree INT)
RETURNS BOOLEAN
DETERMINISTIC
BEGIN    
	
    DECLARE Groupe_p INT;
    DECLARE Liste_p INT;
    
    SELECT COUNT(*) INTO Groupe_p FROM Groupes WHERE Groupe = Gpe;
    
    IF Groupe_p = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "Groupe inexistant";
    ELSE 
		SELECT COUNT(*) INTO Liste_p 
		FROM Reservation r
		WHERE r.Groupe = Gpe AND r.Formation = Forma AND r.Debut = Debut AND r.Duree = Duree;
        
		IF Liste_p = 0 THEN
			RETURN TRUE;
        ELSE 
			RETURN FALSE;
		END IF;
	END IF;
END;
//
DELIMITER ;
