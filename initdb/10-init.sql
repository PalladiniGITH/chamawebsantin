CREATE TABLE IF NOT EXISTS tickets (
  id INT AUTO_INCREMENT PRIMARY KEY,
  description VARCHAR(255)
);
INSERT INTO tickets (description) VALUES ('example ticket');
