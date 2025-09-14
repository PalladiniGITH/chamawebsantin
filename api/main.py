from fastapi import FastAPI, HTTPException
import mysql.connector, os

app = FastAPI()

def get_db():
    user = open('/run/secrets/db_user').read().strip()
    password = open('/run/secrets/db_password').read().strip()
    cnx = mysql.connector.connect(
        host=os.getenv('DB_HOST', 'mysql'),
        database=os.getenv('DB_NAME', 'appdb'),
        user=user,
        password=password
    )
    return cnx

@app.get('/health')
def health():
    return {'status': 'ok'}

@app.get('/tickets')
def get_ticket(id: int):
    cnx = get_db()
    cur = cnx.cursor(prepared=True)
    cur.execute("SELECT id, description FROM tickets WHERE id = %s", (id,))
    row = cur.fetchone()
    cur.close()
    cnx.close()
    if not row:
        raise HTTPException(status_code=404, detail='Not found')
    return {'id': row[0], 'description': row[1]}

@app.post('/login')
def login():
    return {'message': 'login handled by Keycloak'}
