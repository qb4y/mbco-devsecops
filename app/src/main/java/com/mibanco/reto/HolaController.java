package com.mibanco.reto;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HolaController {

    static final String MENSAJE = "Hola Mibanco Challenge";

    @GetMapping("/")
    public String hola() {
        return MENSAJE;
    }
}
