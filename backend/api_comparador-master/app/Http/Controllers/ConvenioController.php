<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class ConvenioController extends Controller
{
    public function all()
    {
        return response(\File::get(storage_path("app/public/simulador/convenios.json")));
    }
}
