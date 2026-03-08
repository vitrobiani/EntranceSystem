use crate::db::Database;
use serialport::SerialPort;
use std::{
    io::{self, BufRead, BufReader},
    sync::Arc,
    time::Duration,
};
use tokio::sync::Notify;

fn arduino_serial_port() -> Box<dyn SerialPort + 'static> {
    let port_name = "/dev/ttyACM0";
    let baud_rate = 9600;

    // opening a serial port to talk to the arduino
    let port = serialport::new(port_name, baud_rate)
        .timeout(Duration::from_millis(10))
        .open()
        .expect("Failed to open port");

    println!("Receiving data on {}...", port_name);
    return port;
}

pub async fn read_loop(db: Database, notify: Arc<Notify>) {
    let port = arduino_serial_port();
    let mut reader = BufReader::new(port);
    let mut buffer = String::new();
    loop {
        read_data(&db, &mut reader, &mut buffer, &notify).await;
    }
}

async fn read_data(
    db: &Database,
    reader: &mut BufReader<Box<dyn SerialPort>>,
    buffer: &mut String,
    notify: &Arc<Notify>,
) -> String {
    match reader.read_line(buffer) {
        Ok(t) if t > 0 => {
            let data = buffer.trim().to_string();
            println!("Received: {}", data);
            buffer.clear();
            let (status, uid) = match data.split_once(" - ") {
                Some((a, b)) => (a, b),
                None => {
                    print!("Error parsing data recived from arduino");
                    ("", "")
                }
            };
            match db.insert_log(uid, status).await {
                Ok(_) => {
                    println!("Data inserted!")
                }
                Err(e) => {
                    println!("Error inserting data: {}", e)
                }
            };
            notify.notify_waiters();
            return data;
        }
        Ok(_) => {} // No data yet
        Err(ref e) if e.kind() == io::ErrorKind::TimedOut => {}
        Err(e) => {
            eprintln!("Error reading: {:?}", e);
        }
    }
    return "".to_string();
}
