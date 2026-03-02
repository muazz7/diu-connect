import { NextResponse } from 'next/server';
import prisma from '@/lib/db';
import { hashPassword, validateStudentIdentity } from '@/lib/auth';

export async function OPTIONS() {
    return new NextResponse(null, {
        status: 204,
        headers: {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        },
    });
}

export async function POST(request: Request) {
    try {
        const body = await request.json();
        const { name, email, studentId, password, role } = body;

        if (!name || !email || !password || !role) {
            return NextResponse.json({ error: 'Missing required fields' }, { status: 400 });
        }

        if (role === 'STUDENT') {
            if (!studentId) {
                return NextResponse.json({ error: 'Student ID is required' }, { status: 400 });
            }
            if (!validateStudentIdentity(studentId, email)) {
                return NextResponse.json({ error: 'Student ID does not match Email' }, { status: 400 });
            }
        }

        const existingUser = await prisma.user.findUnique({ where: { email } });

        if (existingUser) {
            return NextResponse.json({ error: 'User already exists' }, { status: 400 });
        }

        const passwordHash = await hashPassword(password);

        const user = await prisma.user.create({
            data: {
                name,
                email,
                passwordHash,
                role,
                isVerified: true,
            }
        });

        return NextResponse.json({ message: 'User created successfully', userId: user.id }, { status: 201 });

    } catch (error) {
        console.error('Registration error:', error);
        return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
    }
}
