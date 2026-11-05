-- =====================================================
--  밴드 공연 정보·직관 기록 서비스 데이터베이스 (band_db)
--  테이블 7개 / MySQL 8 · MySQL Workbench 기준
--  * 예시 데이터의 밴드·공연·회원은 모두 가상입니다.
--    (공연장 주소만 실제 공연장 주소)
-- =====================================================

-- ===== 0. 처음부터 다시 시작할 때 (기존 band_db 통째로 지우기) =====
DROP DATABASE IF EXISTS band_db;

-- ===== 1. 데이터베이스 만들기 =====
CREATE DATABASE band_db DEFAULT CHARACTER SET utf8mb4;
USE band_db;

-- ===== 2. 테이블 만들기 (칸 + 중복 금지 규칙) =====

-- ① bands 밴드
CREATE TABLE bands (
  band_id    INT          NOT NULL AUTO_INCREMENT,   -- 밴드 번호 (자동)
  band_name  VARCHAR(100) NOT NULL,                  -- 밴드 이름
  PRIMARY KEY (band_id)
);

-- ② venues 공연장
CREATE TABLE venues (
  venue_id    INT          NOT NULL AUTO_INCREMENT,
  venue_name  VARCHAR(100) NOT NULL,                 -- 공연장 이름
  address     VARCHAR(200) NULL,                     -- 주소
  capacity    INT          NULL,                     -- 수용 인원
  PRIMARY KEY (venue_id)
);

-- ③ users 회원
CREATE TABLE users (
  user_id     INT          NOT NULL AUTO_INCREMENT,
  email       VARCHAR(100) NOT NULL,                 -- 이메일 (중복 불가)
  password    VARCHAR(255) NOT NULL,                 -- 비밀번호
  nickname    VARCHAR(30)  NOT NULL,                 -- 닉네임
  created_at  DATETIME     NULL DEFAULT CURRENT_TIMESTAMP, -- 가입 시각
  PRIMARY KEY (user_id),
  UNIQUE INDEX email_UNIQUE (email)
);

-- ④ gigs 공연 (일반 공연 + 페스티벌)
CREATE TABLE gigs (
  gig_id        INT          NOT NULL AUTO_INCREMENT,
  venue_id      INT          NOT NULL,               -- 어느 공연장에서 (FK)
  gig_title     VARCHAR(150) NOT NULL,              -- 공연 이름
  gig_type      ENUM('공연','페스티벌') NOT NULL DEFAULT '공연', -- 구분
  gig_date      DATE         NOT NULL,              -- 공연 날짜 (페스티벌은 시작일)
  end_date      DATE         NULL,                  -- 페스티벌 종료일
  start_time    TIME         NULL,                  -- 시작 시간
  ticket_price  INT          NULL,                  -- 티켓 가격(원)
  PRIMARY KEY (gig_id)
);

-- ⑤ gig_bands 출연 (공연 M : 밴드 N 연결 테이블)
CREATE TABLE gig_bands (
  gig_band_id  INT     NOT NULL AUTO_INCREMENT,
  gig_id       INT     NOT NULL,                     -- 어느 공연에 (FK)
  band_id      INT     NOT NULL,                     -- 어느 밴드가 (FK)
  play_order   TINYINT NULL,                         -- 출연 순서
  PRIMARY KEY (gig_band_id),
  UNIQUE INDEX uk_lineup (gig_id, band_id)           -- 같은 공연에 같은 밴드 두 번 금지
);

-- ⑥ band_follows 팔로우 (회원 M : 밴드 N 연결 테이블)
CREATE TABLE band_follows (
  follow_id    INT      NOT NULL AUTO_INCREMENT,
  user_id      INT      NOT NULL,                    -- 누가 (FK)
  band_id      INT      NOT NULL,                    -- 어떤 밴드를 (FK)
  followed_at  DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (follow_id),
  UNIQUE INDEX uk_follow (user_id, band_id)          -- 같은 밴드 두 번 팔로우 금지
);

-- ⑦ attendances 직관 기록장 (회원 M : 공연 N 연결 테이블) ★ 차별점
CREATE TABLE attendances (
  attendance_id  INT          NOT NULL AUTO_INCREMENT,
  user_id        INT          NOT NULL,              -- 누가 (FK)
  gig_id         INT          NOT NULL,              -- 어떤 공연을 봤는지 (FK)
  memo           VARCHAR(200) NULL,                  -- 한 줄 메모
  created_at     DATETIME     NULL DEFAULT CURRENT_TIMESTAMP, -- 기록한 시각
  PRIMARY KEY (attendance_id),
  UNIQUE INDEX uk_attend (user_id, gig_id)           -- 같은 공연 두 번 기록 금지
);

-- ===== 3. 테이블 연결하기 (FK 7개) =====
-- "자식 표의 이 칸은 부모 표에 있는 번호만 쓸 수 있다"
ALTER TABLE gigs         ADD CONSTRAINT fk_gigs_venue    FOREIGN KEY (venue_id) REFERENCES venues (venue_id);
ALTER TABLE gig_bands    ADD CONSTRAINT fk_gigbands_gig  FOREIGN KEY (gig_id)   REFERENCES gigs (gig_id);
ALTER TABLE gig_bands    ADD CONSTRAINT fk_gigbands_band FOREIGN KEY (band_id)  REFERENCES bands (band_id);
ALTER TABLE band_follows ADD CONSTRAINT fk_follows_user  FOREIGN KEY (user_id)  REFERENCES users (user_id);
ALTER TABLE band_follows ADD CONSTRAINT fk_follows_band  FOREIGN KEY (band_id)  REFERENCES bands (band_id);
ALTER TABLE attendances  ADD CONSTRAINT fk_attend_user   FOREIGN KEY (user_id)  REFERENCES users (user_id);
ALTER TABLE attendances  ADD CONSTRAINT fk_attend_gig    FOREIGN KEY (gig_id)   REFERENCES gigs (gig_id);

-- ===== 4. 데이터 넣기 (가상 예시) — 부모 먼저! =====

INSERT INTO bands (band_name) VALUES
('노을정류장'), ('오렌지크레인'), ('파도소리'), ('새벽다방');

INSERT INTO venues (venue_name, address, capacity) VALUES
('롤링홀', '서울 마포구 어울마당로 35 신보빌딩 지하 1층', NULL),
('언플러그드 라운지', '서울 마포구 와우산로29길 15 2층', NULL),
('올림픽공원 88잔디마당', '서울 송파구 올림픽로 424', NULL);

INSERT INTO users (email, password, nickname) VALUES
('fan01@example.com', 'hash_1234', '노을러버'),
('fan02@example.com', 'hash_5678', '펑크키드');

INSERT INTO gigs (venue_id, gig_title, gig_type, gig_date, end_date, start_time, ticket_price) VALUES
(1, '노을정류장 단독 공연 <저녁 여섯 시>', '공연', '2026-08-22', NULL, '18:00', 40000),
(2, '여름밤 합동 공연', '공연', '2026-09-12', NULL, '19:30', 30000),
(1, '오렌지크레인 단독 공연 <CRANE LIVE>', '공연', '2026-09-27', NULL, '19:00', 35000),
(3, '가을밤 록 페스티벌 2026', '페스티벌', '2026-10-03', '2026-10-04', '13:00', 99000),
(2, '파도소리 단독 공연 <수평선>', '공연', '2026-11-07', NULL, '19:00', 33000),
(1, '노을정류장 X 새벽다방 합동 공연', '공연', '2026-11-21', NULL, '18:00', 38000),
(3, '겨울맞이 록 페스티벌 2026', '페스티벌', '2026-12-05', '2026-12-06', '12:00', 110000);

INSERT INTO gig_bands (gig_id, band_id, play_order) VALUES
(1, 1, 1),
(2, 3, 1), (2, 1, 2),
(3, 2, 1),
(4, 4, 1), (4, 3, 2), (4, 2, 3), (4, 1, 4),
(5, 3, 1),
(6, 4, 1), (6, 1, 2),
(7, 1, 1), (7, 2, 2);

INSERT INTO band_follows (user_id, band_id) VALUES
(1, 1), (1, 3),
(2, 2), (2, 1);

INSERT INTO attendances (user_id, gig_id, memo) VALUES
(1, 1, '앵콜 두 번! 신곡 처음 들음'),
(1, 2, '파도소리를 처음 알게 된 날'),
(1, 4, '비 왔지만 최고였다'),
(2, 3, '슬램 하다가 신발 잃어버림'),
(2, 4, '오렌지크레인 무대만 보러 감');

-- ===== 5. 조회하기 =====

-- [직관 기록장] 1번 회원이 다녀온 공연 (최근 순)
SELECT g.gig_date AS 날짜, g.gig_title AS 공연, v.venue_name AS 공연장, a.memo AS 메모
FROM attendances a
JOIN gigs g   ON a.gig_id = g.gig_id
JOIN venues v ON g.venue_id = v.venue_id
WHERE a.user_id = 1
ORDER BY g.gig_date DESC;

-- [직관 기록장] 1번 회원의 누적 관람 횟수
SELECT COUNT(*) AS 누적_관람_횟수
FROM attendances
WHERE user_id = 1;

-- [직관 기록장] 1번 회원이 가장 많이 본 밴드
SELECT b.band_name AS 밴드, COUNT(*) AS 본_횟수
FROM attendances a
JOIN gig_bands gb ON a.gig_id = gb.gig_id
JOIN bands b      ON gb.band_id = b.band_id
WHERE a.user_id = 1
GROUP BY b.band_id, b.band_name
ORDER BY 본_횟수 DESC
LIMIT 1;

-- [다가오는 공연] 오늘 이후의 일반 공연과 출연 밴드
SELECT g.gig_date AS 날짜, g.start_time AS 시작, g.gig_title AS 공연, v.venue_name AS 공연장,
       GROUP_CONCAT(b.band_name ORDER BY gb.play_order SEPARATOR ', ') AS 출연
FROM gigs g
JOIN venues v     ON g.venue_id = v.venue_id
JOIN gig_bands gb ON g.gig_id = gb.gig_id
JOIN bands b      ON gb.band_id = b.band_id
WHERE g.gig_type = '공연' AND g.gig_date >= CURDATE()
GROUP BY g.gig_id, g.gig_date, g.start_time, g.gig_title, v.venue_name
ORDER BY g.gig_date;

-- [페스티벌] 페스티벌 목록과 라인업
SELECT g.gig_title AS 페스티벌, g.gig_date AS 시작일, g.end_date AS 종료일, v.venue_name AS 장소,
       GROUP_CONCAT(b.band_name ORDER BY gb.play_order SEPARATOR ', ') AS 라인업
FROM gigs g
JOIN venues v     ON g.venue_id = v.venue_id
JOIN gig_bands gb ON g.gig_id = gb.gig_id
JOIN bands b      ON gb.band_id = b.band_id
WHERE g.gig_type = '페스티벌'
GROUP BY g.gig_id, g.gig_title, g.gig_date, g.end_date, v.venue_name
ORDER BY g.gig_date;

-- [팔로우] 밴드별 팔로워 수 (저장하지 않고 COUNT로 계산)
SELECT b.band_name AS 밴드, COUNT(f.follow_id) AS 팔로워
FROM bands b
LEFT JOIN band_follows f ON b.band_id = f.band_id
GROUP BY b.band_id, b.band_name;
