CREATE TABLE data_000D6F0003E16037 (
    "time" timestamp UNIQUE,
    "hardware" real,
    "temp" real, 
    "pressure" real, 
    "humidity" real, 
    "voc" real,
    "light" real,
    "noise" real,
    "noisedba" real NULL,
    "battery" real,
    "shake" boolean,
    "cable" boolean,
    "voc_resistance" real, 
    "rssi" real
);

create index time_000D6F0003E16037_idx on data_000D6F0003E16037(time);

ALTER TABLE ONLY data_000D6F0003E16037
    ADD CONSTRAINT data_000D6F0003E16037_pkey PRIMARY KEY (time);


CREATE TABLE data_000D6F0003117ED0 (
    "time" timestamp UNIQUE,
    "hardware" real,
    "temp" real, 
    "pressure" real, 
    "humidity" real, 
    "voc" real,
    "light" real,
    "noise" real,
    "noisedba" real NULL,
    "battery" real,
    "shake" boolean,
    "cable" boolean,
    "voc_resistance" real, 
    "rssi" real
);

create index time_000D6F0003117ED0_idx on data_000D6F0003117ED0(time);

ALTER TABLE ONLY data_000D6F0003117ED0
    ADD CONSTRAINT data_000D6F0003117ED0_pkey PRIMARY KEY (time);
