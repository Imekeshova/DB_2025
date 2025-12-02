CREATE TABLE users (
 user_id INT PRIMARY KEY,
 username VARCHAR(50),
 email VARCHAR(100),
 subscription_type VARCHAR(20),
 country VARCHAR(50)
);
CREATE TABLE videos (
 video_id INT PRIMARY KEY,
 title VARCHAR(200),
 genre VARCHAR(50),
 release_year INT,
 duration_minutes INT,
 rating DECIMAL(3,1)
);
CREATE TABLE watch_history (
 watch_id INT PRIMARY KEY,
 user_id INT,
 video_id INT,
 watch_date TIMESTAMP,
 watch_duration_minutes INT,
 completed BOOLEAN,
 FOREIGN KEY (user_id) REFERENCES users(user_id),
 FOREIGN KEY (video_id) REFERENCES videos(video_id)
);

---1----
CREATE INDEX idx_watch_history_user_watch_date ON watch_history (user_id, watch_date DESC);


---2---
CREATE INDEX idx_norm_vid_histiry ON videos (lower(trim(title)));

---question---
SELECT video_id, title
FROM videos
WHERE lower(trim(title)) = ' title';


--3----
CREATE INDEX wh_user_idx ON watch_history(user_id);

CREATE INDEX wh_user_date_idx ON watch_history(user_id, watch_date);

CREATE INDEX wh_date_idx ON watch_history(watch_date); ---THIS ONE SHOULD BE DROPPED

---b---
DROP INDEX IF EXISTS  wh_date _idx;

----4----
CREATE INDEX compl_analysez ON watch_history (user_id,  video_id, watch_date)
WHERE completed = TRUE;


