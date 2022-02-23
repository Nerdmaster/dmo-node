package main

import (
	"fmt"
	"log"
	"net"
	"os"
	"time"
)

func main() {
	if len(os.Args) != 5 {
		log.Fatal("Usage: notify <rpc> <coin id> <password> <block hash>")
	}

	var msg = fmt.Sprintf(`{
		"id": 1,
		"method": "mining.update_block",
		"params": [%q,%s,%q]
	}`, os.Args[3], os.Args[2], os.Args[4])

	var rpc = os.Args[1]
	log.Printf("INFO - Sending %q to %q", msg, rpc)

	var stratum, err = net.Dial("tcp", rpc)
	if err != nil {
		log.Printf("ERROR - can't open stratum connection to %s: %s", rpc, err)
		return
	}

	err = stratum.SetWriteDeadline(time.Now().Add(time.Second * 5))
	if err != nil {
		log.Printf("ERROR - can't set deadline on stratum connection to %s: %s", rpc, err)
		return
	}

	var data = []byte(msg)
	var n int
	n, err = stratum.Write(data)
	if err != nil {
		log.Printf("ERROR - can't send request to %s: %s", rpc, err)
		return
	} else if n != len(data) {
		log.Printf("ERROR - can't send request to %s: only able to send %d (of %d) bytes", rpc, n, len(data))
		return
	}

	stratum.Close()
}
