import http from "k6/http";
import { sleep } from "k6";

export let options = {
  stages: [
     { duration: "2m", target: 15 },
     { duration: "3m"},
     { duration: "2m", target: 20  },
     { duration: "5m"},
     { duration: "2m", target: 10},
     { duration: "5m"}
   ]
 };

export default function() {
  var url = "http://<>/event/";
  var payload = JSON.stringify({ data: "test string"});
  var params =  { headers: { "Content-Type": "application/json" } }
  http.post(url, payload, params);
  sleep(1);
};

// docker run -i loadimpact/k6 run - <script.js
