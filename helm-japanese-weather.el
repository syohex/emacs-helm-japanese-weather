;;; helm-japanese-weather.el --- Japanese weather with helm interface

;; Copyright (C) 2014 by Syohei YOSHIDA

;; Author: Syohei YOSHIDA <syohex@gmail.com>
;; URL: https://github.com/syohex/emacs-helm-japanese-weather
;; Version: 0.01
;; Package-Requires: ((helm . "1.56"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;; Code:

(require 'helm)
(require 'json)

(defconst helm-japanese-weather--data-url
  "http://weather.livedoor.com/forecast/rss/primary_area.xml")

(defconst helm-japanese-weather--city-url-base
  "http://weather.livedoor.com/forecast/webservice/json/v1?city=")

(defun helm-japanese-weather--candidates ()
  (with-temp-buffer
    (unless (zerop (call-process "curl" nil t nil "-s" helm-japanese-weather--data-url))
      (error "Can't download: %s" helm-japanese-weather--data-url))
    (goto-char (point-min))
    (let ((regexp "<city\\s-+title=\"\\([^\"]+\\)\"\\s-+id=\"\\([^\"]+\\)\"")
          region-ids)
      (while (re-search-forward regexp nil t)
        (let ((city (match-string-no-properties 1))
              (id (match-string-no-properties 2)))
          (push (cons city id) region-ids)))
      (reverse region-ids))))

(defun helm-japanese-weather--download-city-info (city-id)
  (let ((url (concat helm-japanese-weather--city-url-base city-id)))
    (with-temp-buffer
      (unless (call-process "curl" nil t nil "-s" url)
        (error "Can't download city url"))
      (json-read-from-string (buffer-string)))))

(defun helm-japanese-weather--show-weather (city-id)
  (let* ((data (helm-japanese-weather--download-city-info city-id))
         (description (assoc-default 'description data))
         (title (assoc-default 'title data))
         (forecasts (assoc-default 'forecasts data)))
    (let ((text (assoc-default 'text description))
          (today-forecast (aref forecasts 0)))
      (with-current-buffer (get-buffer-create "*weather*")
        (view-mode -1)
        (erase-buffer)
        (insert (assoc-default 'date today-forecast))
        (insert " " title "\n\n")
        (insert (assoc-default 'telop today-forecast) "\n\n")
        (insert text)
        (view-mode +1)
        (goto-char (point-min))
        (pop-to-buffer (current-buffer))))))

(defvar helm-japanese-weather--source
  '((name . "Japanese Weather")
    (candidates . helm-japanese-weather--candidates)
    (action . (("Show Weather" . helm-japanese-weather--show-weather)))))

;;;###autoload
(defun helm-japanese-weather ()
  (interactive)
  (helm :sources '(helm-japanese-weather--source) :buffer "*helm japanese weather*"))

(provide 'helm-japanese-weather)

;;; helm-japanese-weather.el ends here
