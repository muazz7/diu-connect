import { NextResponse } from 'next/server';
import prisma from '@/lib/db';
import { verifyToken } from '@/lib/auth';

export async function PATCH(request: Request, { params }: { params: Promise<{ id: string }> }) {
    try {
        const authHeader = request.headers.get('Authorization');
        if (!authHeader) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

        const token = authHeader.split(' ')[1];
        const decoded = verifyToken(token) as any;
        if (!decoded || decoded.role !== 'TEACHER') {
            return NextResponse.json({ error: 'Only teachers can modify sections' }, { status: 403 });
        }

        const { id: sectionId } = await params;
        const body = await request.json();
        const { isActive } = body;

        const section = await prisma.section.findUnique({
            where: { id: sectionId },
            include: { course: true }
        });

        if (!section) return NextResponse.json({ error: 'Section not found' }, { status: 404 });
        if (section.course.teacherId !== decoded.userId) {
            return NextResponse.json({ error: 'Not authorized for this section' }, { status: 403 });
        }

        const updatedSection = await prisma.section.update({
            where: { id: sectionId },
            data: { isActive },
        });
        return NextResponse.json(updatedSection);

    } catch (e: any) {
        console.error("Request Error:", e);
        return NextResponse.json({ error: `Request failed: ${e.message}` }, { status: 500 });
    }
}
